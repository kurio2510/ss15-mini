CREATE DATABASE Mini_Social_Network;
USE Mini_Social_Network;
-- TABLE 
CREATE TABLE users(
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts(
    post_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    content TEXT NOT NULL,
    like_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE comments(
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    post_id INT,
    user_id INT,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE TABLE friends(
    friendship_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    friend_id INT,
    status VARCHAR(20) CHECK(status IN ('pending', 'accepted')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (friend_id) REFERENCES users(user_id) ON DELETE CASCADE,
    UNIQUE(user_id,friend_id)
);

CREATE TABLE likes(
    like_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    post_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(post_id) ON DELETE CASCADE,
    UNIQUE (user_id, post_id)
);

-- DATA 
INSERT INTO users(username, password, email) VALUES
('john_doe', 'pass123', 'john@gmail.com'),
('sarah99', 'pass123', 'sarah@gmail.com'),
('michael_k', 'pass123', 'michael@gmail.com'),
('linda_dev', 'pass123', 'linda@gmail.com'),
('tommy', 'pass123', 'tommy@gmail.com');

INSERT INTO posts(user_id, content, like_count, comment_count) VALUES
(1, 'Just joined this social app!', 3, 2),
(2, 'Working on a new web project', 2, 1),
(3, 'Database design is very important', 4, 3),
(4, 'Enjoying backend programming lately', 1, 1),
(5, 'Anyone learning MySQL here?', 2, 2);

INSERT INTO comments(post_id, user_id, content) VALUES
(1, 2, 'Welcome to the platform!'),
(1, 3, 'Hope you enjoy it here'),
(2, 1, 'Good luck with your project'),
(3, 4, 'Absolutely true'),
(3, 5, 'Normalization matters a lot'),
(4, 2, 'Backend is really fun'),
(5, 1, 'Yes, currently studying triggers'),
(5, 3, 'Learning procedures too');

INSERT INTO friends(user_id, friend_id, status) VALUES
(1, 2, 'accepted'),
(1, 4, 'accepted'),
(2, 3, 'pending'),
(3, 5, 'accepted'),
(4, 5, 'pending');

INSERT INTO likes(user_id, post_id) VALUES
(1, 2),
(2, 1),
(3, 1),
(4, 3),
(5, 3),
(1, 3),
(2, 5),
(3, 5),
(5, 2);

-- cn1: VIEW
CREATE VIEW view_user_info AS
SELECT user_id, username, email, created_at
FROM users;

-- cn2: PROCEDURE thêm user
DELIMITER //

CREATE PROCEDURE sp_add_user(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100)
)
BEGIN
    IF EXISTS (SELECT 1 FROM users WHERE email = p_email) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email đã tồn tại';
    ELSE
        INSERT INTO users(username,password,email)
        VALUES(p_username,p_password,p_email);
    END IF;
END //

DELIMITER ;

-- cn3: TRIGGER cập nhật like/comment
DELIMITER //

CREATE TRIGGER tg_comment_insert
AFTER INSERT ON comments
FOR EACH ROW
BEGIN
    UPDATE posts
    SET comment_count = comment_count + 1
    WHERE post_id = NEW.post_id;
END //

CREATE TRIGGER tg_comment_delete
AFTER DELETE ON comments
FOR EACH ROW
BEGIN
    UPDATE posts
    SET comment_count = comment_count - 1
    WHERE post_id = OLD.post_id;
END //

CREATE TRIGGER tg_like_insert
AFTER INSERT ON likes
FOR EACH ROW
BEGIN
    UPDATE posts
    SET like_count = like_count + 1
    WHERE post_id = NEW.post_id;
END //

CREATE TRIGGER tg_like_delete
AFTER DELETE ON likes
FOR EACH ROW
BEGIN
    UPDATE posts
    SET like_count = like_count - 1
    WHERE post_id = OLD.post_id;
END //

DELIMITER ;

-- cn4: Báo cáo hoạt động user
DELIMITER //

CREATE PROCEDURE sp_user_activity_report()
BEGIN
    SELECT 
        u.user_id,
        u.username,
        COUNT(DISTINCT p.post_id) AS total_posts,
        COUNT(DISTINCT c.comment_id) AS total_comments,
        COUNT(DISTINCT l.like_id) AS total_likes
    FROM users u
    LEFT JOIN posts p ON u.user_id = p.user_id
    LEFT JOIN comments c ON u.user_id = c.user_id
    LEFT JOIN likes l ON u.user_id = l.user_id
    GROUP BY u.user_id, u.username;
END //

DELIMITER ;

-- cn5: Xóa user
DELIMITER //
CREATE PROCEDURE sp_delete_user(IN p_user_id INT)
BEGIN
    DELETE FROM users
    WHERE user_id = p_user_id;
END //
DELIMITER ;

-- cn6: Thêm bạn bè
DELIMITER //

CREATE PROCEDURE sp_add_friend(
    IN p_user1 INT,
    IN p_user2 INT
)
BEGIN
    IF p_user1 = p_user2 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Không thể tự kết bạn';
    END IF;

    INSERT INTO friends(user_id, friend_id, status)
    VALUES(p_user1, p_user2, 'pending');
END //

DELIMITER ;