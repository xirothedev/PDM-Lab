package educonnect;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String URL =
            "jdbc:mysql://localhost:33306/educonnect?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String USER = "root";
    private static final String PASS = "root";

    /**
     * Opens and returns a new Connection.
     * CALLER IS RESPONSIBLE FOR CLOSING IT.
     * Always use in try-with-resources.
     */
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(URL, USER, PASS);
    }

    // Private constructor — this class should never be instantiated
    private DBConnection() {}
}
