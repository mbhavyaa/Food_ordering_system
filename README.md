# Food Ordering System

A database-driven food ordering system designed as a **DBMS project**. The project focuses on modeling the operations of an online food delivery platform through a relational database, covering customers, restaurants, menus, orders, reviews, and food donation records.

## Overview

The system demonstrates how a food ordering platform can be structured using a relational database. It includes interfaces that showcase the intended user experience while emphasizing database design, relationships, and CRUD operations.

A unique aspect of the project is the proposed **food donation workflow**, where restaurants can record surplus food to facilitate donations to nearby NGOs, promoting sustainable food management.

## Features

* Customer registration and login
* Restaurant and menu management
* Food browsing and ordering interface
* Customer reviews and ratings
* Order management
* Food donation module (concept)

## Database Design

The database models entities such as:

*customer – Stores user details like name, email, address, and phone.
*Restaurant – Contains restaurant info such as name, cuisine, and rating.
*MenuItem – Lists food items offered by restaurants with price and category.
*Order – Stores each order's user, restaurant, date, status, and total amount.
*OrderDetail – Line-items of an order (each food item + quantity).
*Delivery – Tracks delivery agent, delivery status, and linked order.
*Payment – Stores payment mode and payment status for each order.
*Review – User ratings and comments for restaurants.
*LeftoverFood – Stores leftover food details offered for donation by restaurants.
*NGO – Stores NGO information like contact person and address.
*FoodDonation – Links leftover food to NGOs with collection time and status.

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/6fe1e815-3212-4df7-964b-9035ba0068d4" />

![public/images/ER-diagram.png]

The schema demonstrates the use of:

* Primary and foreign keys
* Entity relationships
* Normalized tables
* CRUD operations
* SQL queries for data management

## Tech Stack

* HTML
* CSS
* JavaScript
* PostgreSQL

## Note

This repository was developed as an academic **Database Management Systems (DBMS)** project. The primary focus is on database design and demonstrating the application's workflow rather than providing a production-ready backend.


