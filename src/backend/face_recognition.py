import cv2
import numpy as np
import torch
from facenet_pytorch import InceptionResnetV1
from PIL import Image
import torchvision.transforms as transforms

# Check if GPU is available
device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')

# Loading the pre-trained InceptionResnetV1 model from facenet_pytorch
model = InceptionResnetV1(pretrained='vggface2').eval().to(device)

# Load Haar cascade for face detection
haar_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def detect_face(img_path):
    # Load the image using OpenCV
    img = cv2.imread(img_path)
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)

    # Detect faces using Haar cascade
    faces = haar_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=5, minSize=(30, 30))
    if len(faces) == 0:
        return None, None

    # Crop the first detected face
    (x, y, w, h) = faces[0]
    face_img = img[y:y+h, x:x+w]

    # Convert face_img to PIL Image
    face_img = Image.fromarray(cv2.cvtColor(face_img, cv2.COLOR_BGR2RGB))
    return face_img, Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))

def get_face_embedding(face_img):
    # Preprocess the image to the size the model was trained on
    face_img = face_img.resize((160, 160))
    face_img = transforms.ToTensor()(face_img).unsqueeze(0).to(device)

    # Run inference
    with torch.no_grad():
        embedding = model(face_img).cpu().numpy()

    print("Generated embedding shape:", embedding.shape)  # Debugging line
    return embedding[0]

def recognize_face(embedding, user_embeddings):
    # Compare the embeddings and find the best match
    print("Current embedding shape:", embedding.shape)  # Debugging line
    min_dist = float("inf")
    best_match = None
    for user, user_embedding in user_embeddings.items():
        user_embedding = user_embedding[:512]
        print("User embedding shape:", user_embedding.shape)  # Debugging line
        dist = np.linalg.norm(embedding - user_embedding)
        if dist < min_dist:
            min_dist = dist
            best_match = user
    return best_match
