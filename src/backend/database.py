import os
import mysql.connector
import pickle
from datetime import datetime
import hashlib
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives import padding
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import base64
from hashlib import sha256

def create_database_if_not_exists():
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password=""
    )
    cursor = connection.cursor()
    cursor.execute("CREATE DATABASE IF NOT EXISTS election2")
    cursor.close()
    connection.close()

def get_db_connection():
    create_database_if_not_exists()
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="election2"
    )

def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INT AUTO_INCREMENT PRIMARY KEY,
            email VARCHAR(255) NOT NULL UNIQUE,
            password VARCHAR(255) NOT NULL,
            phone VARCHAR(15) NOT NULL,
            embedding BLOB NOT NULL,
            is_admin BOOLEAN NOT NULL DEFAULT 0,
            has_voted BOOLEAN NOT NULL DEFAULT 0
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS votes (
            id INT AUTO_INCREMENT PRIMARY KEY,
            -- user_id INT NOT NULL,
            candidate VARCHAR(255) UNIQUE,
            vote_count INT NOT NULL DEFAULT 0
            -- FOREIGN KEY(user_id) REFERENCES users(id)
        )
    ''')
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS candidates (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL
        )
    ''')  
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS election (
        id INT AUTO_INCREMENT PRIMARY KEY,
        start_time DATETIME,
        end_time DATETIME,
        is_enabled BOOLEAN NOT NULL DEFAULT 0
    )
''')
    conn.commit()
    cursor.close()
    conn.close()

# AES encryption and decryption
AES_KEY = os.environ.get("AES_KEY", "your_aes_key_32_bytes")  # Ensure this is 32 bytes for AES-256

def derive_key(key):
    """Derive a 256-bit AES key using SHA-256 hash."""
    return sha256(key.encode()).digest()

def encrypt_embedding(embedding):
    """Encrypts the embedding using AES encryption."""
    key = derive_key(AES_KEY)
    backend = default_backend()
    iv = os.urandom(16)  # 16 bytes initialization vector (IV)
    
    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=backend)
    encryptor = cipher.encryptor()
    
    padder = padding.PKCS7(algorithms.AES.block_size).padder()
    padded_data = padder.update(pickle.dumps(embedding)) + padder.finalize()
    
    encrypted = encryptor.update(padded_data) + encryptor.finalize()
    return base64.b64encode(iv + encrypted).decode('utf-8')  # Store IV with the ciphertext

def decrypt_embedding(encrypted_embedding):
    """Decrypts the embedding using AES decryption."""
    key = derive_key(AES_KEY)
    backend = default_backend()

    # No need to encode if it's already in bytes
    if isinstance(encrypted_embedding, str):
        encrypted_embedding = encrypted_embedding.encode('utf-8')

    encrypted_data = base64.b64decode(encrypted_embedding)
    iv = encrypted_data[:16]  # Extract the first 16 bytes for the IV
    ciphertext = encrypted_data[16:]

    cipher = Cipher(algorithms.AES(key), modes.CBC(iv), backend=backend)
    decryptor = cipher.decryptor()

    decrypted_padded_data = decryptor.update(ciphertext) + decryptor.finalize()

    unpadder = padding.PKCS7(algorithms.AES.block_size).unpadder()
    decrypted_data = unpadder.update(decrypted_padded_data) + unpadder.finalize()

    return pickle.loads(decrypted_data)



def hash_password(password):
    # Hash the password with SHA-256
    sha256 = hashlib.sha256()
    sha256.update(password.encode('utf-8'))  # Convert the password to bytes
    return sha256.hexdigest()

def register_user(email, password, phone, embedding, is_admin=False):
    conn = get_db_connection()
    cursor = conn.cursor()
    hashed_password = hash_password(password)

     # Encrypt the embedding before storing it in the database
    encrypted_embedding = encrypt_embedding(embedding)

    cursor.execute('''
        INSERT INTO users (email, password, phone, embedding, is_admin)
        VALUES (%s, %s, %s, %s, %s)
    ''', (email, hashed_password, phone, encrypted_embedding, is_admin))
    conn.commit()
    cursor.close()
    conn.close()

def update_user_password(user_id, new_password):
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        hashed_password = hash_password(new_password)

        # SQL query to update the password
        cursor.execute('''
            UPDATE users SET password = %s WHERE id = %s
        ''', (hashed_password, user_id))

        conn.commit()
        cursor.close()
        conn.close()

        return True
    except Exception as e:
        print(f"Error updating password: {str(e)}")
        return False


def get_user_embedding(email):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT embedding FROM users WHERE email = %s
    ''', (email,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    
    if row:
        # Decrypt the embedding after retrieving it from the database
        encrypted_embedding = row[0]
        return decrypt_embedding(encrypted_embedding)

    return None

# def get_user_email_by_id(user_id):
#     conn = get_db_connection()
#     cursor = conn.cursor()

#     query = '''SELECT email FROM users WHERE id = %s'''
#     cursor.execute(query, (user_id,))
#     result = cursor.fetchone()

#     cursor.close()
#     conn.close()

#     if result:
#         return result[0]  # Return email
#     return None


def record_vote(user_id, candidate):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO votes (user_id, candidate)
        VALUES (%s, %s)
    ''', (user_id, candidate))
    conn.commit()
    cursor.close()
    conn.close()


# ('SELECT id FROM users WHERE email = %s AND password = %s', (email, password))
def authenticate_user(email, password):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT id, password FROM users WHERE email = %s', (email,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    # if row:
    #     return row[0]
    # return None
    if row:
        user_id, stored_hashed_password = row
        
        # Hash the provided password
        hashed_password = hash_password(password)
        
        # Compare the provided hashed password with the stored hashed password
        if hashed_password == stored_hashed_password:
            return user_id
    return None

def is_admin(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT is_admin FROM users WHERE id = %s
    ''', (user_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if row and row[0] == 1:
        return True
    return False

def set_admin(email):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            UPDATE users
            SET is_admin = 1
            WHERE email = %s
        ''', (email,))  # Parameters should be a tuple
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def add_user(email, password, phone):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO users (email, password, phone)
            VALUES (%s, %s, %s)
        ''', (email, password, phone))
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def delete_user(email):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            DELETE FROM users WHERE email = %s
        ''', (email,))
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def add_candidate(candidate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO candidates (name)
            VALUES (%s)
        ''', (candidate,))
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def delete_candidate(candidate):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            DELETE FROM candidates WHERE name = %s
        ''', (candidate,))
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def get_candidates():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT name FROM candidates
    ''')
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return [row[0] for row in rows]

def get_users():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT email FROM users
    ''')
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    return [user[0] for user in users]

def user_has_voted(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT 1 FROM votes WHERE user_id = %s
    ''', (user_id,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    return row is not None

# def set_election_time(start_time, end_time):
#     conn = get_db_connection()
#     cursor = conn.cursor()
#     try:
#         cursor.execute('''
#             INSERT INTO election (start_time, end_time)
#             VALUES (%s, %s)
#         ''', (start_time, end_time))
#         conn.commit()
#         return True
#     except mysql.connector.Error as err:
#         print(f"Error: {err}")
#         return False
#     finally:
#         cursor.close()
#         conn.close()

def set_election_time(start_time, end_time, is_enabled):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO election (id, start_time, end_time, is_enabled)
            VALUES (1, %s, %s, %s)
            ON DUPLICATE KEY UPDATE
                start_time = VALUES(start_time),
                end_time = VALUES(end_time),
                is_enabled = VALUES(is_enabled)
        ''', (start_time, end_time, is_enabled))
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def disable_election_time():
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute('''
            INSERT INTO election (id, is_enabled)
            VALUES (1, 0)
            ON DUPLICATE KEY UPDATE
                is_enabled = VALUES(is_enabled)
        ''')
        conn.commit()
        return True
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()

def get_current_election():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute('SELECT * FROM election')               
        result = cursor.fetchone()
        # print(result)
        return result
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return None
    finally:
        cursor.close()
        conn.close()


def get_election_time():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = '''
            SELECT start_time, end_time
            FROM election
            WHERE is_enabled = 1
            ORDER BY start_time DESC LIMIT 1
        '''
        cursor.execute(query)
        result = cursor.fetchone()
        return result
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return None
    finally:
        cursor.close()
        conn.close()

def is_election_enabled():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        query = '''
            SELECT is_enabled
            FROM election
            ORDER BY start_time DESC LIMIT 1
        '''
        cursor.execute(query)
        result = cursor.fetchone()
        if result:
            return result.get('is_enabled', 0) == 1
        return False
    except mysql.connector.Error as err:
        print(f"Error: {err}")
        return False
    finally:
        cursor.close()
        conn.close()



def get_election_results():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        
        SELECT candidate, vote_count
        FROM votes
        GROUP BY candidate
    ''')
    rows = cursor.fetchall()
    cursor.close()
    conn.close()
    return [{'candidate': row[0], 'vote_count': row[1]} for row in rows]

def authenticate_user_by_phone(phone):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        SELECT id,email FROM users WHERE phone = %s
    ''', (phone,))
    row = cursor.fetchone()
    cursor.close()
    conn.close()
    if row:
        return (row[0],row[1])
    return None

def get_user_voting_status(user_id):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT has_voted FROM users WHERE id = %s', (user_id,))
    user = cursor.fetchone()
    cursor.close()
    conn.close()
    return user[0] if user else None

def update_user_voting_status(user_id, has_voted):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('UPDATE users SET has_voted = %s WHERE id = %s', (has_voted, user_id))
    conn.commit()
    cursor.close()
    conn.close()

def get_candidate_id(candidate_name):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('SELECT id FROM candidates WHERE name = %s', (candidate_name,))
    candidate = cursor.fetchone()
    cursor.close()
    conn.close()
    return candidate[0] if candidate else None

def increment_vote(candidate_name):
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute('''
        INSERT INTO votes (candidate, vote_count)
        VALUES (%s, 1)
        ON DUPLICATE KEY UPDATE vote_count = vote_count + 1
    ''', (candidate_name,))
    conn.commit()
    cursor.close()
    conn.close()

