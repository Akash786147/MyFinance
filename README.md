# MyFinance - Personal Finance Tracker

## Overview

MyFinance is a Flutter-based personal finance tracker that helps users efficiently manage their incomes and expenses. With features such as transaction management, category organization, financial insights, and data persistence, MyFinance provides an intuitive and seamless experience for budgeting and financial tracking. The app also includes authentication, data synchronization, and notifications for due payments.

## Features

### 1. **Transaction Management**

- Add a new transaction (income/expense)
  - Fields: **Title, Amount, Transaction Type (Income/Expense), Category, Date**
- Edit or delete existing transactions
- View transaction history

### 2. **Category Management**

- Users can define and manage their own categories (e.g., “Groceries,” “Rent,” “Salary,” “Entertainment”)
- UI to **add, edit, or delete categories**

### 3. **Financial Overview Dashboard**

- Total **income** and **expenses** for the current month
- Net balance (**Income - Expenses**)
- Simple chart visualization showing **spending per category**

### 4. **Data Persistence**

- Data is stored securely and persists even after closing the app

### 5. **Navigation & State Management**

- Once a transaction is added, the list screen refreshes immediately

### 6. **Notifications & Reminders**

- Send reminders when a recurring payment is due

## Installation

### Prerequisites

Ensure you have the following installed:

- Flutter SDK (latest version)
- Dart
- Android Studio or Visual Studio Code (with Flutter plugin)

### Steps to Run the Project

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/MyFinance.git
   ```
2. Navigate to the project folder:
   ```bash
   cd MyFinance
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run the application:
   ```bash
   flutter run
   ```



## Tech Stack

- **Flutter** - Frontend framework
- **Dart** - Programming language
- **SharedPreferences** - Local storage

