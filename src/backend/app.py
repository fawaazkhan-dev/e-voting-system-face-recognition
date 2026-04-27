from flask import Flask, request, jsonify
from flask_cors import CORS
from face_recognition import detect_face, get_face_embedding, recognize_face
# from database import init_db, register_user, get_user_embedding, record_vote, authenticate_user, is_admin as check_is_admin, add_user, delete_user, add_candidate, delete_candidate, get_candidates, user_has_voted, set_election_time, get_election_results
from database import init_db, register_user, get_user_embedding, record_vote, authenticate_user, is_admin as check_is_admin, add_user, delete_user, add_candidate, delete_candidate, get_candidates, user_has_voted, set_election_time, disable_election_time, get_election_time, is_election_enabled, get_current_election, get_election_results, get_user_voting_status, update_user_voting_status, get_candidate_id, increment_vote, authenticate_user_by_phone, set_admin, get_users, update_user_password
import ssl
import random
import string
import os
from datetime import datetime
from twilio.rest import Client

app = Flask(__name__)
CORS(app)

# Initialize the database
init_db()

# Twilio configuration
TWILIO_ACCOUNT_SID = 'AC7a9bbe140c1e3fa280e4f7b15999479f'
TWILIO_AUTH_TOKEN = 'cf7cd8859b1ee97b0820a1727fabe060'
TWILIO_PHONE_NUMBER = '+15162657170'

client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

otp_storage = {}


def generate_otp():
    return ''.join(random.choices(string.digits, k=6))

@app.route('/register', methods=['POST'])
def register():
    email = request.form['email']
    password = request.form['password']
    phone = request.form['phone']
    file = request.files['face_image']

    file_path = 'uploads/' + file.filename
    file.save(file_path)

    face, _ = detect_face(file_path)
    if face is None:
        return jsonify({'error': 'No face detected'}), 400

    embedding = get_face_embedding(face)
    register_user(email, password, phone, embedding)
    return jsonify({'success': True})

# @app.route('/login', methods=['POST'])
# def login():
#     email = request.form['email']
#     password = request.form['password']

#     user_id = authenticate_user(email, password)
#     if user_id:
#         otp = generate_otp()
#         otp_storage[email] = otp
#         # Here you should integrate with an SMS API to send the OTP to the user's phone
#         print(f"OTP for {email}: {otp}")  # For debugging purposes only
#         return jsonify({'success': True, 'user_id': user_id})
#     return jsonify({'error': 'Invalid credentials'}), 401

@app.route('/login', methods=['POST'])
def login():
    email = request.form['email']
    password = request.form['password']

    user_id = authenticate_user(email, password)
    if user_id:
        otp = generate_otp()
        otp_storage[email] = otp
        # Integrate with an SMS API to send the OTP to the user's phone (when re-enabled)
        print(f"OTP for {email}: {otp}")  # For debugging purposes only
        
        is_admin = check_is_admin(user_id)
        
        return jsonify({'success': True, 'user_id': user_id, 'is_admin': is_admin})
    return jsonify({'error': 'Invalid credentials'}), 401


@app.route('/change-password', methods=['POST'])
def change_password():
    try:
        # data = request.get_json()
        user_id = int(request.form['userId'])
        new_password = request.form['new_password']

        # Update password in the database using the function in database.py
        success = update_user_password(user_id, new_password)

        if success:
            return jsonify({'success': True,'message': 'Password updated successfully'}), 200
        else:
            return jsonify({'message': 'Failed to update password'}), 500

    except Exception as e:
        return jsonify({'message': 'Error occurred', 'error': str(e)}), 500


# @app.route('/verify-otp', methods=['POST'])
# def verify_otp():
#     phone = request.form['phone']
#     otp = request.form['otp']
#     email = request.form['email']

#     if otp_storage.get(email) == otp:
#         return jsonify({'success': True})
#     return jsonify({'error': 'Invalid OTP'}), 4011

# @app.route('/verify-otp', methods=['POST'])
# def verify_otp():
#     phone = request.form['phone']
#     otp = request.form['otp']
#     email = request.form['email']

#     if otp_storage.get(email) == otp:
#         # Get user_id by phone or email
#         user_id = authenticate_user_by_phone(phone)
        
#         if user_id is None:
#             return jsonify({'error': 'User not found'}), 404

#         # Check if the user is an admin
#         admin_status = check_is_admin(user_id)
        
#         return jsonify({'success': True, 'is_admin': admin_status})
    
#     return jsonify({'error': 'Invalid OTP'}), 401



@app.route('/send-otp', methods=['POST'])
def send_otp():
    phone = request.form['phone']

    if not phone:
        return jsonify({'error': 'Phone number is required'}), 400

    otp = generate_otp()

    # Send OTP via SMS using Twilio
    message = client.messages.create(
        body=f'Your OTP is {otp}',
        from_=TWILIO_PHONE_NUMBER,
        to=phone
    )

    print(f"OTP for {phone}: {otp}")
    otp_storage[phone] = otp
    return jsonify({'success': True, 'message': 'OTP sent successfully'}), 200

@app.route('/verify-otp', methods=['POST'])
def verify_otp():
    phone = request.form['phone']
    otp = request.form['otp']

    stored_otp = otp_storage.get(phone)

    if stored_otp and stored_otp == otp:
        user_id,email = authenticate_user_by_phone(phone)
        print(user_id, email)
        return jsonify({'success': True, 'user_id': user_id, 'email':email}), 200
    else:
        # return jsonify({'success': False, 'error': 'Invalid OTP'}), 400
        return jsonify({'error': 'Invalid OTP'}), 400


# @app.route('/get-user-email/<int:user_id>', methods=['GET'])
# def get_user_email(user_id):
#     try:
#         email = get_user_email_by_id(user_id)  # Fetch email from DB using the user_id
#         if email:
#             return jsonify({'status': 200, 'email': email}), 200
#         else:
#             return jsonify({'status': 404, 'message': 'User not found'}), 404
#     except Exception as e:
#         return jsonify({'status': 500, 'message': str(e)}), 500

# @app.route('/vote', methods=['POST'])
# def vote():
#     user_id = request.form['user_id']
#     candidate = request.form['candidate']
    
#     if not user_id or not candidate:
#         return jsonify({'error': 'Invalid data provided'}), 400

#     if user_has_voted(user_id):
#         return jsonify({'error': 'User has already voted'}), 400
    
#     record_vote(user_id, candidate)
#     return jsonify({'success': True})

@app.route('/vote', methods=['POST'])
def vote():
    user_id = request.form['user_id']
    candidate_name = request.form['candidate']

    # Check if the user has already voted
    has_voted = get_user_voting_status(user_id)
    if has_voted == 1:
        return jsonify({'error': 'User has already voted'}), 400

    # Check if candidate exists and increment vote count
    candidate_id = get_candidate_id(candidate_name)
    if not candidate_id:
        return jsonify({'error': 'Candidate not found'}), 400

    increment_vote(candidate_name)
    update_user_voting_status(user_id, 1)

    return jsonify({'success': True})

@app.route('/candidates', methods=['GET'])
def candidates():
    return jsonify(get_candidates())

@app.route('/users', methods=['GET'])
def fetch_users():
    return jsonify(get_users())

@app.route('/is_admin', methods=['GET'])
def is_admin():
    user_id = request.args.get('user_id')
    if check_is_admin(user_id):
        return jsonify({'is_admin': True})
    return jsonify({'is_admin': False})

@app.route('/set-admin', methods=['POST'])
def set_admin_route():
    email = request.form['email']
    
    if set_admin(email):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to set user as admin'}), 400

@app.route('/add-user', methods=['POST'])
def add_user_route():
    email = request.form['email']
    password = request.form['password']
    phone = request.form['phone']
    if add_user(email, password, phone):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to add user'}), 400

@app.route('/delete-user', methods=['DELETE'])
def delete_user_route():
    email = request.args.get('email')
    if delete_user(email):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to delete user'}), 400

@app.route('/add-candidate', methods=['POST'])
def add_candidate_route():
    candidate = request.form['candidate']
    if add_candidate(candidate):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to add candidate'}), 400

@app.route('/delete-candidate', methods=['DELETE'])
def delete_candidate_route():
    candidate = request.args.get('candidate')
    if delete_candidate(candidate):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to delete candidate'}), 400

# @app.route('/set-election-time', methods=['POST'])
# def set_election_time_route():
#     start_time = request.form['start_time']
#     end_time = request.form['end_time']
#     if set_election_time(start_time, end_time):
#         return jsonify({'success': True})
#     return jsonify({'error': 'Failed to set election time'}), 400

@app.route('/set-election-time', methods=['POST'])
def set_election_time_route():
    start_time = request.form.get('start_time')
    end_time = request.form.get('end_time')
    is_enabled = request.form.get('is_enabled') == 'true'
    if set_election_time(start_time, end_time, is_enabled):
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to set election time'}), 400

@app.route('/disable-election-time', methods=['POST'])
def disable_election_time_route():
    if disable_election_time():
        return jsonify({'success': True})
    return jsonify({'error': 'Failed to disable election time'}), 400

# @app.route('/check-election-time', methods=['GET'])
# def check_election_time_route():
#     election = get_current_election()
#     if election:
#         return jsonify({'is_within_time': True})
#     return jsonify({'is_within_time': False})

# @app.route('/check-election-time', methods=['GET'])
# def check_election_time_route():
#     current_time = datetime.now()
#     election = get_current_election()

#     if election.is_enabled == 0:
#             return jsonify({'is_within_time': True})
#     elif election and election.is_enabled == 1 and election.start_time <= current_time <= election.end_time:
#         return jsonify({'is_within_time': True})
#     return jsonify({'is_within_time': False})

@app.route('/get-election-time', methods=['GET'])
def get_election_time_route():
    election_time = get_election_time()
    if election_time:
        return jsonify(election_time)
    return jsonify({'error': 'No election time set'}), 404

@app.route('/check-election-enabled', methods=['GET'])
def check_election_enabled_route():
    enabled = is_election_enabled()
    return jsonify({'is_enabled': enabled})

@app.route('/check-election-time', methods=['GET'])
def check_election_time_route():
    current_time = datetime.now()
    election = get_current_election()
    # print(election)

    # If election is found and enabled, check if within the allowed time
    if election:
        if election['is_enabled'] == 0:
            return jsonify({'is_within_time': True})
        elif election['is_enabled'] == 1 and election['start_time'] <= current_time <= election['end_time']:
            return jsonify({'is_within_time': True})
    
    return jsonify({'is_within_time': False})

@app.route('/check-election-status', methods=['GET'])
def check_election_status_route():
    election = get_current_election()
    
    if election['is_enabled'] == 1:
        return jsonify({'succes': True, 'election_enabled': True, 'is_enabled': True})
            
    return jsonify({'election_enabled': False, 'is_enabled': False})


# @app.route('/disable-election-time', methods=['POST'])
# def disable_election_time_route():
#     if set_election_time(None, None, False):
#         return jsonify({'success': True})
#     return jsonify({'error': 'Failed to disable election time'}), 400


@app.route('/results', methods=['GET'])
def results():
    return jsonify(get_election_results())

@app.route('/detect-face', methods=['POST'])
def detect_face_route():
    file = request.files['image']
    file_path = 'uploads/' + file.filename
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    file.save(file_path)

    face, _ = detect_face(file_path)
    if face is None:
        return jsonify({'error': 'No face detected'}), 400

    return jsonify({'success': True})

@app.route('/recognize-face', methods=['POST'])
def recognize_face_route():
    file = request.files['image']
    file_path = 'uploads/' + file.filename
    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    file.save(file_path)

    face, _ = detect_face(file_path)
    if face is None:
        return jsonify({'error': 'No face detected'}), 400

    embedding = get_face_embedding(face)
    # user_embeddings = {user['email']: get_user_embedding(user['email']) for user in get_users()}
    user_embeddings = {user: get_user_embedding(user) for user in get_users()}
    best_match = recognize_face(embedding, user_embeddings)
    if best_match:
        return jsonify({'success': True, 'user': best_match})
    return jsonify({'error': 'Face not recognized'}), 400

if __name__ == '__main__':
    # context = ssl.SSLContext(ssl.PROTOCOL_TLS)
    # context.load_cert_chain('cert.pem', 'key.pem')
    # app.run(debug=True, ssl_context=context)
    # app.run(host='0.0.0.0', port=5000, ssl_context=context)
    app.run(debug=True, host='0.0.0.0', port=5000, ssl_context=('cert.pem','key.pem'))
    # app.run(debug=True, host='0.0.0.0', port=5000)
    