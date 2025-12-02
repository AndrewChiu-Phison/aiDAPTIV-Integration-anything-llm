# Chat with YouTube Videos User Guide

## Overview
This application allows users to store video content in the KV Cache, enabling them to select specific videos for QA interactions. This functionality achieves quick responses from the LLM, enhancing the overall user experience.

---
## Chapter 1: Installation and Setting

### Installation Steps

```bash
git clone <repository-url>
cd aiDAPTIV-Integration-anything-llm
```
```bash
yarn dev:all
```

---

## Chapter 2: How to Use?

### Usage Workflow

1. **Initial Setup**
- Click on `anything-llm.exe` to launch the chat interface. The chat room can be found at http://localhost:3000 (default). 
![image](img/fig_1.PNG)

2. **Set LLM Endpoint**
- Fill in the **LLM Endpoint** and **Model Name** as required.
![image](img/fig_2.PNG)
![image](img/fig_3.PNG)

3. **Set RAG**
- Upload the txt as a reference to the question.
![image](img/fig_4.PNG)
![image](img/fig_5.PNG)
![image](img/fig_6.PNG)
![image](img/fig_7.PNG)

4. **Ask questions**
- Put "@agent" in the questions to enable the functionality of the RAG system. You can start asking questions about the txt you uploaded.
![image](img/fig_8.PNG)
