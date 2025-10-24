# 📘 Study Pro – E-Learning Platform

## 📑 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture & System Design](#architecture--system-design)
3. [User Interface Documentation](#user-interface-documentation)
4. [API Integration](#api-integration)

---

## 1. Project Overview

### 📌 Project Summary
**Study Pro** is an online learning platform that connects teachers and students through comprehensive course management and **AI-powered features**.  

### ✨ Key Features
- **Course Management**: Video uploads, PDF resources, external links  
- **User Dashboards**: Separate interfaces for students and teachers  
- **AI Integration**: Gemini-powered chat, PDF analysis, grammar checking, quiz generation  
- **Social Features**: Real-time messaging, reviews, ratings  
- **Content Access**: Video streaming with progress tracking  

### 🛠 Technology Stack
- **Frontend**: Flutter  
- **Backend**: Firebase Auth, Firestore  
- **Database**: NoSQL Database  
- **AI Integration**: Google Gemini API  

---

## 2. Architecture & System Design

### 📊 Activity Diagram
<p align="center">
  <img src="../activity_diagram.jpeg" alt="Activity Diagram" width="600"/>
</p>

### 🔄 Flowchart
<p align="center">
  <img src="../flow_chart.png" alt="Flowchart" width="600"/>
</p>

---

## 3. User Interface Documentation

### 🔐 Authentication Screens (Pic 1 – Light Mode, Pic 2 – Dark Mode)
- **Login, Sign Up, Forgot Password** integrated with **Firebase Authentication**  
<p align="center">
  <img src="../Picture1.png" alt="Auth Light" width="300"/>
  <img src="../Picture2.png" alt="Auth Dark" width="300"/>
</p>

---

### 🏠 Home Screen & Dashboards (Pic 3 & 4)
- **Course Categories**  
- **Student Abstract Dashboard** (progress overview)  
- **Detailed Dashboard** (videos watched, skills acquired)  
<p align="center">
  <img src="../Picture3.png" alt="Home Light" width="300"/>
  <img src="../Picture4.png" alt="Home Dark" width="300"/>
</p>

---

### 📚 Course Details & Video Player (Pic 5)
- Course discovery, details, reviews  
- Structured video playlist with progress tracking  
- Resource downloads & external links  
<p align="center">
  <img src="../Picture5.png" alt="Course Screen" width="500"/>
</p>

---

### 💬 Chatting Screen (Pic 6)
- Real-time messaging between students  
- Simple, structured chat format  
<p align="center">
  <img src="../Picture6.png" alt="Chat Screen" width="500"/>
</p>

---

### 🤖 AI-Powered Screen (Pic 7)
- **Chat with Gemini** (text & images)  
- **Chat with PDF** (ask questions about PDF contents)  
- **Grammar Check** (text improvements)  
- **Quiz Generation** from prompts  
<p align="center">
  <img src="../Picture7.png" alt="AI Screen" width="500"/>
</p>

---

### ⚙️ Settings Screen (Pic 8)
- Profile management & photo upload  
- Dark/Light theme switch  
- Help & support access  
- App review & feedback  
- Learning streaks for motivation  
- Secure logout  
<p align="center">
  <img src="../Picture8.png" alt="Settings Screen" width="500"/>
</p>

---

## 4. API Integration

- **Firebase Authentication** → User sign-in & account management  
- **Firestore Database** → Course data, chat messages, user profiles  
- **Google Gemini API** →  
  - AI Chat (text/image inputs)  
  - PDF understanding & Q&A  
  - Grammar correction  
  - Quiz generation  

---

## 📄 Documentation
For a complete report including all screenshots, download:  
👉 [📕 Full Project Report (PDF)](../docs/project_report.pdf)  
