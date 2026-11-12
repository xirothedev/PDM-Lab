package educonnect;

import javax.swing.*;
import javax.swing.table.DefaultTableModel;
import java.sql.*;
import java.util.List;

public class MainFrame extends JFrame {

    private JTextField txtQuery;
    private JButton btnExecute;
    private JTable tblResults;
    private JLabel lblStatus;
    private DefaultTableModel tableModel;

    // search panel
    private JTextField txtName;
    private JButton btnSearchStudent;
    private DefaultTableModel searchModel;
    private JTable tblSearch;

    public MainFrame() {
        setTitle("EduConnect Query Runner");
        setSize(900, 600);
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLocationRelativeTo(null);
        initComponents();
    }

    private void initComponents() {
        txtQuery = new JTextField(40);
        btnExecute = new JButton("Execute");
        tableModel = new DefaultTableModel();
        tblResults = new JTable(tableModel);
        lblStatus = new JLabel("Ready");

        JPanel topPanel = new JPanel();
        topPanel.add(new JLabel("SQL:"));
        topPanel.add(txtQuery);
        topPanel.add(btnExecute);

        // search panel
        txtName = new JTextField(20);
        btnSearchStudent = new JButton("Search Student");
        searchModel = new DefaultTableModel(new String[]{"StudentName","TotalEnrolled","AverageGrade"}, 0);
        tblSearch = new JTable(searchModel);
        JPanel searchPanel = new JPanel();
        searchPanel.add(new JLabel("Name:"));
        searchPanel.add(txtName);
        searchPanel.add(btnSearchStudent);

        JPanel south = new JPanel();
        south.add(lblStatus);

        JSplitPane split = new JSplitPane(JSplitPane.VERTICAL_SPLIT,
                new JScrollPane(tblResults), new JScrollPane(tblSearch));
        split.setResizeWeight(0.6);

        JPanel north = new JPanel();
        north.setLayout(new BoxLayout(north, BoxLayout.Y_AXIS));
        north.add(topPanel);
        north.add(searchPanel);

        add(north, "North");
        add(split, "Center");
        add(south, "South");

        btnExecute.addActionListener(e -> runQuery());
        btnSearchStudent.addActionListener(e -> runSearch());
    }

    private void runQuery() {
        String sql = txtQuery.getText().trim();
        if (sql.isEmpty()) {
            JOptionPane.showMessageDialog(this, "Query cannot be empty");
            return;
        }

        btnExecute.setEnabled(false);
        lblStatus.setText("Running...");
        tableModel.setRowCount(0);
        tableModel.setColumnCount(0);

        SwingWorker<Void, Void> worker = new SwingWorker<>() {
            @Override
            protected Void doInBackground() throws Exception {
                try (
                    Connection conn = DBConnection.getConnection();
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ResultSet rs = ps.executeQuery()
                ) {
                    ResultSetMetaData meta = rs.getMetaData();
                    int cols = meta.getColumnCount();

                    String[] headers = new String[cols];
                    for (int i = 1; i <= cols; i++) {
                        headers[i - 1] = meta.getColumnLabel(i);
                    }
                    SwingUtilities.invokeLater(() -> {
                        for (String h : headers) tableModel.addColumn(h);
                    });

                    while (rs.next()) {
                        Object[] row = new Object[cols];
                        for (int i = 1; i <= cols; i++) row[i - 1] = rs.getObject(i);
                        final Object[] finalRow = row;
                        SwingUtilities.invokeLater(() -> tableModel.addRow(finalRow));
                    }
                } catch (SQLException e) {
                    SwingUtilities.invokeLater(() ->
                        JOptionPane.showMessageDialog(MainFrame.this,
                             "Error: " + e.getMessage(), "SQL Error",
                             JOptionPane.ERROR_MESSAGE));
                }
                return null;
            }

            @Override
            protected void done() {
                btnExecute.setEnabled(true);
                lblStatus.setText("Done");
            }
        };
        worker.execute();
    }

    private void runSearch() {
        String name = txtName.getText().trim();
        searchModel.setRowCount(0);
        List<String[]> rows = StudentSearch.searchByName(name);
        for (String[] r : rows) searchModel.addRow(r);
    }

    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> new MainFrame().setVisible(true));
    }
}
