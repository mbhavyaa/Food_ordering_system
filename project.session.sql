
CREATE TABLE if not exists customer(
    UserID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL CHECK (Email LIKE '%@%.%'),
    Address VARCHAR(255),
    Phone VARCHAR(15)
);

CREATE TABLE if not exists Restaurant (
    RestID SERIAL PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    CuisineType VARCHAR(50),
    Rating DECIMAL(2,1)
);

CREATE TABLE if not exists MenuItem (
    ItemID SERIAL PRIMARY KEY,
    RestID INT REFERENCES Restaurant(RestID),
    Name VARCHAR(100),
    Price DECIMAL(8,2),
    Category VARCHAR(50)
);

CREATE TABLE if not exists  "Order" (
    OrderID SERIAL PRIMARY KEY,
    UserID INT REFERENCES customer(UserID),
    RestID INT REFERENCES Restaurant(RestID),
    OrderDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(20),
    TotalAmount DECIMAL(8,2)
);

CREATE TABLE if not exists  OrderDetail (
    OrderID INT REFERENCES "Order"(OrderID),
    ItemID INT REFERENCES MenuItem(ItemID),
    Quantity INT,
    PRIMARY KEY (OrderID, ItemID)
);

CREATE TABLE if not exists  Delivery (
    DeliveryID SERIAL PRIMARY KEY,
    OrderID INT REFERENCES "Order"(OrderID),
    AgentID INT,
    DeliveryStatus VARCHAR(30)
);

CREATE TABLE if not exists  Payment (
    PaymentID SERIAL PRIMARY KEY,
    OrderID INT REFERENCES "Order"(OrderID),
    PaymentMode VARCHAR(20),
    Status VARCHAR(20)
);

CREATE TABLE if not exists  Review (
    ReviewID SERIAL PRIMARY KEY,
    UserID INT REFERENCES customer(UserID),
    RestID INT REFERENCES Restaurant(RestID),
    Rating DECIMAL(2,1),
    Comment TEXT
);

CREATE TABLE if not exists  LeftoverFood (
    LeftoverID SERIAL PRIMARY KEY,
    RestID INT REFERENCES Restaurant(RestID),
    ItemName VARCHAR(100) NOT NULL,
    Quantity INT NOT NULL,
    ExpiryTime TIMESTAMP,
    Status VARCHAR(20) DEFAULT 'Available'
);

CREATE TABLE if not exists  NGO (
    NGOID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    ContactPerson VARCHAR(100),
    Phone VARCHAR(15),
    Address VARCHAR(255)
);

CREATE TABLE if not exists  FoodDonation (
    DonationID SERIAL PRIMARY KEY,
    NGOID INT REFERENCES NGO(NGOID),
    LeftoverID INT REFERENCES LeftoverFood(LeftoverID),
    CollectionTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Status VARCHAR(20) DEFAULT 'Pending'
);


/*CREATE OR REPLACE FUNCTION validate_user_email()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Email NOT LIKE '%@%.%' THEN
        RAISE EXCEPTION 'Invalid email format for user: %', NEW.Email;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS check_user_email ON customer;
CREATE TRIGGER check_user_email
BEFORE INSERT OR UPDATE ON customer
FOR EACH ROW
EXECUTE FUNCTION validate_user_email();

-- 🍴 RESTAURANT TABLE: Keep rating within 0–5
CREATE OR REPLACE FUNCTION limit_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Rating < 0 THEN
        NEW.Rating := 0;
    ELSIF NEW.Rating > 5 THEN
        NEW.Rating := 5;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS rating_check ON Restaurant;
CREATE TRIGGER rating_check
BEFORE INSERT OR UPDATE ON Restaurant
FOR EACH ROW
EXECUTE FUNCTION limit_restaurant_rating();
*/


ALTER TABLE Restaurant
ADD CONSTRAINT valid_rating CHECK (Rating BETWEEN 0 AND 5);

ALTER TABLE MenuItem
ADD CONSTRAINT positive_price CHECK (Price > 0);

ALTER TABLE Review
    ADD CONSTRAINT review_rating_check CHECK (Rating BETWEEN 1 AND 5);

/*-- 🍕 MENUITEM TABLE: Prevent negative/zero price
CREATE OR REPLACE FUNCTION check_price_positive()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Price <= 0 THEN
        RAISE EXCEPTION 'Item price must be positive';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS price_check ON MenuItem;
CREATE TRIGGER price_check
BEFORE INSERT OR UPDATE ON MenuItem
FOR EACH ROW
EXECUTE FUNCTION check_price_positive();
*/

-- 🧾 ORDER TABLE: Auto-set order date if null
CREATE OR REPLACE FUNCTION set_order_date()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.OrderDate IS NULL THEN
        NEW.OrderDate := NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS order_date_auto ON "Order";
CREATE TRIGGER order_date_auto
BEFORE INSERT ON "Order"
FOR EACH ROW
EXECUTE FUNCTION set_order_date();


--ORDERDETAIL TABLE: Update total amount automatically
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE "Order"
    SET TotalAmount = (
        SELECT SUM(m.Price * od.Quantity)
        FROM OrderDetail od
        JOIN MenuItem m ON od.ItemID = m.ItemID
        WHERE od.OrderID = NEW.OrderID
    )
    WHERE OrderID = NEW.OrderID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS total_update ON OrderDetail;
CREATE TRIGGER total_update
AFTER INSERT OR UPDATE OR DELETE ON OrderDetail
FOR EACH ROW
EXECUTE FUNCTION update_order_total();


--DELIVERY TABLE: Sync delivery + order status
CREATE OR REPLACE FUNCTION sync_order_delivery_status()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.DeliveryStatus = 'Delivered' THEN
        UPDATE "Order"
        SET Status = 'Delivered'
        WHERE OrderID = NEW.OrderID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS delivery_status_sync ON Delivery;
CREATE TRIGGER delivery_status_sync
AFTER UPDATE ON Delivery
FOR EACH ROW
EXECUTE FUNCTION sync_order_delivery_status();


--  PAYMENT TABLE: Update order when payment succeeds
CREATE OR REPLACE FUNCTION mark_order_paid()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status = 'Success' THEN
        UPDATE "Order"
        SET Status = 'Paid'
        WHERE OrderID = NEW.OrderID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS payment_success_update ON Payment;
CREATE TRIGGER payment_success_update
AFTER INSERT OR UPDATE ON Payment
FOR EACH ROW
EXECUTE FUNCTION mark_order_paid();


--  REVIEW TABLE: Auto-update restaurant rating
CREATE OR REPLACE FUNCTION recalc_restaurant_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE Restaurant
    SET Rating = (
        SELECT ROUND(AVG(Rating)::numeric, 1)
        FROM Review
        WHERE RestID = NEW.RestID
    )
    WHERE RestID = NEW.RestID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS review_rating_update ON Review;
CREATE TRIGGER review_rating_update
AFTER INSERT OR UPDATE ON Review
FOR EACH ROW
EXECUTE FUNCTION recalc_restaurant_rating();


-- 🥡 LEFTOVERFOOD TABLE: Auto-log food donation
CREATE OR REPLACE FUNCTION log_food_donation()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO FoodDonation (NGOID, LeftoverID, Status)
    VALUES (NULL, NEW.LeftoverID, 'Pending');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_leftover_added ON LeftoverFood;
CREATE TRIGGER after_leftover_added
AFTER INSERT ON LeftoverFood
FOR EACH ROW
EXECUTE FUNCTION log_food_donation();


-- ❤️ FOODDONATION TABLE: Mark leftover as donated
CREATE OR REPLACE FUNCTION mark_leftover_collected()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status = 'Collected' THEN
        UPDATE LeftoverFood
        SET Status = 'Donated'
        WHERE LeftoverID = NEW.LeftoverID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS donation_status_sync ON FoodDonation;
CREATE TRIGGER donation_status_sync
AFTER UPDATE ON FoodDonation
FOR EACH ROW
EXECUTE FUNCTION mark_leftover_collected();




-- 👤 User
/*INSERT INTO customer (Name, Email, Address, Phone) VALUES
('Bhavya Maheshwari', 'bhavya@gmail.com', 'Delhi', '9876543210'),
('Aarav Sharma', 'aarav@gmail.com', 'Gurgaon', '9812345678'),
('Riya Singh', 'riya@gmail.com', 'Noida', '9823456789');

-- 🍴 Restaurant
INSERT INTO Restaurant (Name, CuisineType, Rating) VALUES
('Café Aroma', 'Indian', 4.5),
('Pizza Palace', 'Italian', 4.3),
('Green Bowl', 'Healthy', 4.7);

-- 🍕 MenuItem
INSERT INTO MenuItem (RestID, Name, Price, Category) VALUES
(1, 'Paneer Tikka', 180.00, 'Main Course'),
(1, 'Masala Chai', 50.00, 'Beverage'),
(2, 'Cheese Burst Pizza', 299.00, 'Main Course'),
(2, 'Garlic Bread', 120.00, 'Starter'),
(3, 'Quinoa Salad', 220.00, 'Salad'),
(3, 'Smoothie Bowl', 250.00, 'Dessert');

-- 🧾 Order
INSERT INTO "Order" (UserID, RestID, OrderDate, Status, TotalAmount) VALUES
(1, 1, NOW(), 'Confirmed', 230.00),
(2, 2, NOW(), 'Delivered', 419.00),
(3, 3, NOW(), 'Pending', 470.00);

-- 📦 OrderDetail
INSERT INTO OrderDetail (OrderID, ItemID, Quantity) VALUES
(1, 1, 1),
(1, 2, 1),
(2, 3, 1),
(2, 4, 1),
(3, 5, 1),
(3, 6, 1);

-- 🚚 Delivery
INSERT INTO Delivery (OrderID, AgentID, DeliveryStatus) VALUES
(1, 101, 'Delivered'),
(2, 102, 'Delivered'),
(3, 103, 'Out for Delivery');

-- 💳 Payment
INSERT INTO Payment (OrderID, PaymentMode, Status) VALUES
(1, 'UPI', 'Success'),
(2, 'Credit Card', 'Success'),
(3, 'Cash on Delivery', 'Pending');

-- 🌟 Review
INSERT INTO Review (UserID, RestID, Rating, Comment) VALUES
(1, 1, 4.5, 'Tasty food and quick delivery!'),
(2, 2, 4.0, 'Pizza was good but crust a bit thick.'),
(3, 3, 5.0, 'Loved the healthy options!');

-- 🥡 LeftoverFood
INSERT INTO LeftoverFood (RestID, ItemName, Quantity, ExpiryTime, Status) VALUES
(1, 'Paneer Tikka', 5, NOW() + INTERVAL '4 hours', 'Available'),
(2, 'Garlic Bread', 8, NOW() + INTERVAL '6 hours', 'Available');

-- 🏢 NGO
INSERT INTO NGO (Name, ContactPerson, Phone, Address) VALUES
('Helping Hands', 'Neha Verma', '9998887777', 'Rohini, Delhi'),
('Food For All', 'Manish Gupta', '9887766554', 'Connaught Place, Delhi');

-- ❤️ FoodDonation
INSERT INTO FoodDonation (NGOID, LeftoverID, CollectionTime, Status) VALUES
(1, 1, NOW(), 'Collected'),
(2, 2, NOW(), 'Pending');

DO $$
BEGIN
  FOR i IN 1..20 LOOP
    INSERT INTO customer (Name, Email, Address, Phone)
    VALUES (
      'User_' || i,
      'user' || i || '@example.com',
      'City_' || (i % 5 + 1),
      '98' || lpad((10000000 + i)::text, 8, '0')
    );
  END LOOP;
END $$;
*/