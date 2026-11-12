package educonnect;

import java.sql.Connection;
import java.sql.SQLException;

public class ConnectionLeakTest {
    public static void main(String[] args) {
        for (int i = 0; i < 200; i++) {
            try {
                Connection conn = DBConnection.getConnection();
                // deliberately NOT closing
                System.out.println("Opened connection " + (i + 1));
            } catch (SQLException e) {
                System.err.println("Failed at connection " + (i + 1) + ": " + e.getMessage());
                System.err.println("SQLState: " + e.getSQLState() + " ErrorCode: " + e.getErrorCode());
                break;
            }
        }
    }
}
