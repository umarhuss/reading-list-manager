-- Reading List Manager Database Schema
--
-- This file defines the database structure for the Reading List Manager application.
-- It includes tables for users and books with appropriate constraints and relationships.

-- users table

-- Table to store user account information
CREATE TABLE IF NOT EXISTS users (
    -- Primary key with auto-incrementing ID
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Username must be unique and not nullable
    username TEXT UNIQUE NOT NULL,

    -- Hashed password (never store plain text passwords!)
    password_hash TEXT NOT NULL,

    -- Timestamp when the user account was created
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- Constraints to ensure data integrity
    CONSTRAINT users_username_length CHECK (LENGTH(username) >= 3 AND LENGTH(username) <= 30),
    CONSTRAINT users_username_format CHECK (username GLOB '[A-Za-z0-9_-]*')
);

-- books table

-- Table to store book information for each user
CREATE TABLE IF NOT EXISTS books (
    -- Primary key with auto-incrementing ID
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    -- Book title (required)
    title TEXT NOT NULL,

    -- Book author (optional)
    author TEXT,

    -- Book genre (optional)
    genre TEXT,

    -- Reading status with predefined values
    status TEXT CHECK(status IN ('read', 'reading', 'to-read')) DEFAULT 'to-read',

    -- Personal notes about the book (optional)
    notes TEXT,

    -- Foreign key linking to the users table
    user_id INTEGER NOT NULL,

    -- Timestamp when the book was added
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- Timestamp when the book was last updated
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- Foreign key constraint ensuring referential integrity
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,

    -- Additional constraints for data validation
    CONSTRAINT books_title_length CHECK (LENGTH(title) >= 1 AND LENGTH(title) <= 255),
    CONSTRAINT books_author_length CHECK (author IS NULL OR LENGTH(author) <= 255),
    CONSTRAINT books_genre_length CHECK (genre IS NULL OR LENGTH(genre) <= 100),
    CONSTRAINT books_notes_length CHECK (notes IS NULL OR LENGTH(notes) <= 1000)
);

-- indexes for performance

-- Index on user_id for faster book queries by user
-- This is crucial for performance when fetching a user's books
CREATE INDEX IF NOT EXISTS idx_books_user_id ON books(user_id);

-- Index on status for filtering books by reading status
CREATE INDEX IF NOT EXISTS idx_books_status ON books(status);

-- Index on genre for filtering and public statistics
CREATE INDEX IF NOT EXISTS idx_books_genre ON books(genre);

-- Index on author for public statistics and search
CREATE INDEX IF NOT EXISTS idx_books_author ON books(author);

-- Composite index for user books with status filtering
CREATE INDEX IF NOT EXISTS idx_books_user_status ON books(user_id, status);

-- Index on created_at for ordering books by when they were added
CREATE INDEX IF NOT EXISTS idx_books_created_at ON books(created_at);

-- views for common queries (optional)

-- view to get book statistics by user (useful for dashboards)
CREATE VIEW IF NOT EXISTS user_book_stats AS
SELECT
    u.id as user_id,
    u.username,
    COUNT(b.id) as total_books,
    COUNT(CASE WHEN b.status = 'read' THEN 1 END) as books_read,
    COUNT(CASE WHEN b.status = 'reading' THEN 1 END) as books_reading,
    COUNT(CASE WHEN b.status = 'to-read' THEN 1 END) as books_to_read
FROM users u
LEFT JOIN books b ON u.id = b.user_id
GROUP BY u.id, u.username;

-- View for public book statistics (anonymised)
CREATE VIEW IF NOT EXISTS public_book_stats AS
SELECT
    title,
    author,
    genre,
    COUNT(*) as times_added,
    COUNT(CASE WHEN status = 'read' THEN 1 END) as times_read
FROM books
WHERE title IS NOT NULL
GROUP BY title, author, genre
HAVING times_added > 1  -- only show books added by multiple users
ORDER BY times_added DESC;
