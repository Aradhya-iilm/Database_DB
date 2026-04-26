CREATE DATABASE Dashboard_db;
GO
USE Dashboard_db;
GO

-- ROLES TABLE (normalized)
CREATE TABLE Roles_ (
    role_id INT IDENTITY PRIMARY KEY,
    role_name VARCHAR(20) UNIQUE NOT NULL
);

INSERT INTO Roles_ VALUES ('Admin'), ('Analyst'), ('Viewer');


-- USERS TABLE
CREATE TABLE Users_ (
    user_id INT IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role_id INT,
    created_at DATETIME DEFAULT GETDATE(),
    last_login DATETIME NULL,

    FOREIGN KEY (role_id) REFERENCES Roles_(role_id)
);


-- DATASETS
CREATE TABLE Datasets_ (
    dataset_id INT IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    dataset_name VARCHAR(150) NOT NULL,
    is_active BIT DEFAULT 1,
    created_at DATETIME DEFAULT GETDATE(),

    CONSTRAINT unique_dataset UNIQUE (user_id, dataset_name),
    FOREIGN KEY (user_id) REFERENCES Users_(user_id)
);


-- CATEGORIES
CREATE TABLE Categories_ (
    category_id INT IDENTITY PRIMARY KEY,
    category_name VARCHAR(100) UNIQUE NOT NULL
);


-- DATA ENTRIES (optimized)
CREATE TABLE Data_Entries_ (
    entry_id INT IDENTITY PRIMARY KEY,
    dataset_id INT NOT NULL,
    entry_date DATE NOT NULL,
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    category_id INT,
    is_deleted BIT DEFAULT 0,
    created_at DATETIME DEFAULT GETDATE(),
    updated_at DATETIME NULL,

    FOREIGN KEY (dataset_id) REFERENCES Datasets_(dataset_id),
    FOREIGN KEY (category_id) REFERENCES Categories_(category_id)
);


-- CHART CONFIG
CREATE TABLE Charts_ (
    chart_id INT IDENTITY PRIMARY KEY,
    dataset_id INT NOT NULL,
    chart_type VARCHAR(50),
    config_json NVARCHAR(MAX), -- store chart settings
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (dataset_id) REFERENCES Datasets_(dataset_id)
);


-- REPORTS
CREATE TABLE Reports_ (
    report_id INT IDENTITY PRIMARY KEY,
    user_id INT,
    report_name VARCHAR(150),
    report_data NVARCHAR(MAX),
    generated_date DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES Users_(user_id)
);


-- LOGS (FIXED)
CREATE TABLE Logs_ (
    log_id INT IDENTITY PRIMARY KEY,
    user_id INT,
    activity VARCHAR(255),
    created_at DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (user_id) REFERENCES Users_(user_id)
);



CREATE INDEX idx_data_date ON Data_Entries_(entry_date);
CREATE INDEX idx_data_dataset ON Data_Entries_(dataset_id);
CREATE INDEX idx_data_category ON Data_Entries_(category_id);
CREATE INDEX idx_user_email ON Users_(email);



CREATE TRIGGER trg_insert_log
ON Data_Entries_
AFTER INSERT
AS
BEGIN
    INSERT INTO Logs_ (user_id, activity)
    SELECT d.user_id, 'New data entry added'
    FROM inserted i
    JOIN Datasets_ d ON i.dataset_id = d.dataset_id;
END;


CREATE PROCEDURE GetDashboardStats
    @dataset_id INT
AS
BEGIN
    SELECT 
        COUNT(*) AS total_entries,
        SUM(amount) AS total_revenue,
        AVG(amount) AS avg_revenue
    FROM Data_Entries_
    WHERE dataset_id = @dataset_id AND is_deleted = 0;

    SELECT 
        entry_date,
        SUM(amount) AS total
    FROM Data_Entries_
    WHERE dataset_id = @dataset_id AND is_deleted = 0
    GROUP BY entry_date
    ORDER BY entry_date;

    SELECT 
        c.category_name,
        SUM(d.amount) AS total
    FROM Data_Entries_ d
    JOIN Categories c ON d.category_id = c.category_id
    WHERE dataset_id = @dataset_id AND is_deleted = 0
    GROUP BY c.category_name;
END;