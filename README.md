# MeMoSA Clinical Platform

This project, titled **"Clinical Data Platform for Oral Lesion Diagnosis with Integrated AI Evaluation Using Deep Learning"** is a **prototype clinical data platform** that integrates a **mobile app, backend, database, and AI service** to support oral lesion case management and diagnosis.

The platform is designed to:

- **Enable comparison between human and AI diagnoses** of oral lesion types in real-world settings.
- **Support clinicians and researchers** in evaluating the reliability and effectiveness of AI in clinical workflows.
- **Leverage deep learning models (CNNs)** to classify camera-captured oral lesion images into three categories: **Cancer, Oral Potentially Malignant Disorders (OPMDs), and Others**.

---

## Objectives

1. **Develop deep learning models** for classifying oral lesion images into Cancer, OPMDs, and Others, using advanced training strategies and augmentation techniques.
2. **Evaluate model performance**, aiming for an **AUC-ROC ≥ 0.90**, and compare AI classification against clinician diagnoses.
3. **Build a mobile-based GUI prototype** that integrates AI support for oral lesion diagnosis and validate its usability through **User Acceptance Testing (UAT)** with clinicians and researchers.

---

## Table of Contents

- [Features](#features)
- [Architecture / Components](#architecture--components)
- [Tech Stack](#tech-stack)

---

## Features

- Create / edit clinical case drafts for patients
- Upload & preview consent forms (PDF, images, Word docs)
- Capture images of specific oral cavity areas (9 required regions)
- Save drafts locally, delete drafts, or submit case data to backend
- Public & private case data separation
- Mobile UI + backend service integration
- Validation of required fields (e.g., all images, consent form, mandatory case info)

---

## Architecture & Components

The project comprises multiple parts:

- **mobile_app**: Flutter mobile client for users (study coordinators, clinicians and admins) to fill case forms, pick/preview files, capture/upload images, save drafts, and submit.
- **backend**: Server / cloud functions or APIs to receive submitted case data, handle storage, manage database records.
- **firebase**: Likely used for authentication, file storage (images, consent forms), and real-time / Firestore / database services.
- **.ai** folder: (?) Contains AI-related models or scripts (if any) used for image processing, classification, or assistance.
- Supporting config / workflows: CI/CD, GitHub Actions (in `.github/workflows`), VSCode settings, etc.

---

## Tech Stack

| Component     | Technology                            |
| ------------- | ------------------------------------- |
| Mobile Client | Dart & Flutter                        |
| Database      | Firebase (Auth / Firestore / Storage) |
| Backend       | FastAPI custom backend                |

---
