<?php
// Securely fetch credentials injected by Ansible/PHP-FPM environment variables
$host = getenv('DB_HOST') ?: "localhost"; 
$username = getenv('DB_USER') ?: "admin";
$password = getenv('DB_PASS') ?: "password";
$dbname = getenv('DB_NAME') ?: "student_db";

// Create connection
$conn = new mysqli($host, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Database Connection failed. Please try again later.");
}

// Capture data safely from POST
$name = isset($_POST['name']) ? htmlspecialchars($_POST['name']) : '';
$email = isset($_POST['email']) ? htmlspecialchars($_POST['email']) : '';
$phone = isset($_POST['phone']) ? htmlspecialchars($_POST['phone']) : '';
$place = isset($_POST['place']) ? htmlspecialchars($_POST['place']) : '';

if (!empty($name) && !empty($email)) {
    // Prepare SQL statement to insert data safely
    // (Using prepared statements prevents SQL Injection attacks)
    $stmt = $conn->prepare("INSERT INTO students (name, email, phone, place) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("ssss", $name, $email, $phone, $place);

    if ($stmt->execute()) {
        // Success Page matching your premium web layout
        echo "
        <!DOCTYPE html>
        <html lang='en'>
        <head>
            <meta charset='UTF-8'>
            <title>Registration Successful</title>
            <style>
                body {
                    background-color: #fcf6f5;
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif;
                    color: #2c2c2c;
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    height: 100vh;
                    margin: 0;
                }
                .success-container {
                    background-color: #ffffff;
                    padding: 40px;
                    border-radius: 16px;
                    box-shadow: 0px 10px 30px rgba(0,0,0,0.04);
                    text-align: center;
                    width: 400px;
                    border: 1px solid rgba(0,0,0,0.02);
                }
                h1 { color: #e89c9c; font-weight: 600; margin-top: 0; }
                p { color: #757575; font-size: 15px; line-height: 1.6; margin-bottom: 25px; }
                .btn-back {
                    display: inline-block;
                    padding: 12px 24px;
                    background-color: #f3b0b0;
                    color: white;
                    text-decoration: none;
                    border-radius: 8px;
                    font-weight: 600;
                    font-size: 14px;
                    transition: all 0.2s ease;
                    box-shadow: 0px 4px 12px rgba(243, 176, 176, 0.3);
                }
                .btn-back:hover {
                    background-color: #e89c9c;
                    transform: translateY(-1px);
                }
            </style>
        </head>
        <body>
            <div class='success-container'>
                <h1>Success!</h1>
                <p>Thank you, <strong>$name</strong>.<br>Your student registration details have been securely saved to the database cluster.</p>
                <a href='index.html' class='btn-back'>Go Back to Form</a>
            </div>
        </body>
        </html>";
    } else {
        echo "Execution Error: " . $stmt->error;
    }
    $stmt->close();
} else {
    echo "Invalid Form Submission.";
}

$conn->close();
?>