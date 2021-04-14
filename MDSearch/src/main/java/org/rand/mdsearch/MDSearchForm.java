/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package org.rand.mdsearch;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URL;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.concurrent.locks.ReentrantLock;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import javax.imageio.ImageIO;
import javax.swing.DefaultListModel;
import javax.swing.JOptionPane;
import javax.swing.ListModel;
import javax.swing.SwingWorker;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;
import javax.swing.table.DefaultTableModel;
import org.sqlite.ProgressHandler;
import org.sqlite.SQLiteConfig;

/**
 *
 * @author chunky
 */
public class MDSearchForm extends javax.swing.JFrame {

    Connection conn = null;
    
    boolean cancelCurrentSearch = false;
    ReentrantLock queryLock = new ReentrantLock();
    int db_progresssteps = 0;
    final String dbFileName = "milliondigits.sqlite";
    
    /**
     * Creates new form MDSearchForm
     */
    public MDSearchForm() {

        initComponents();
       
        try {
            URL logorsc = Thread.currentThread().getContextClassLoader().getResource("randlogo.gif");
            if(null != logorsc) {
                BufferedImage icon = ImageIO.read(logorsc);
                this.setIconImage(icon);
            }
        } catch(IOException ex) {
            // Silently swallow. Only for iconimage
        }
        
        
        DefaultListModel<String> encodingListModel = new DefaultListModel<>();
        // Cp1047 => EBCDIC
        String encodings[] = new String[] { "US-ASCII", "Cp1047", "UTF-16" };
        for(String enc : encodings) {
            encodingListModel.addElement(enc);
        }
        encodingList.setModel(encodingListModel);
        encodingList.setSelectionInterval(0, encodings.length-1);
        
        setLocationRelativeTo(null);
        
        searchText.addActionListener(new ActionListener() {
            @Override
            public void actionPerformed(ActionEvent e) {
                doSearchThread(searchText.getText());
            }
        });
        
        searchText.getDocument().addDocumentListener(new DocumentListener() {
            @Override
            public void insertUpdate(DocumentEvent e) {
                doSearchThread(searchText.getText());
            }

            @Override
            public void removeUpdate(DocumentEvent e) {
                doSearchThread(searchText.getText());
            }

            @Override
            public void changedUpdate(DocumentEvent e) {
                doSearchThread(searchText.getText());
            }
        });
    }

    private Connection connectDb() throws SQLException {
        SQLiteConfig sqlcf = new SQLiteConfig();
        sqlcf.setSynchronous(SQLiteConfig.SynchronousMode.OFF);
        
        Connection c = DriverManager.getConnection("jdbc:sqlite:" + dbFileName, sqlcf.toProperties());
        c.setAutoCommit(false);
        
        ProgressHandler.setHandler(c, 1000000, new ProgressHandler() {
            @Override
            protected int progress() throws SQLException {
                db_progresssteps++;
                searchProgress.setValue(db_progresssteps);
                int cancelCode = cancelCurrentSearch?1:0;
                cancelCurrentSearch = false;
                return cancelCode;
            }
        });
        
        return c;
    }
    
    public void doSearchThread(final String searchstr) {
        cancelCurrentSearch = true;
        SwingWorker worker = new SwingWorker() {
            @Override
            protected Object doInBackground() throws Exception {
                try {
                    queryLock.lock();
                    db_progresssteps = 0;
                    doSearch(searchstr);
                } finally {
                    queryLock.unlock();
                }
                return null;
            }
        };
        worker.execute();
    }

    public void setSearch(final String searchstr) {
        searchText.setText(searchstr);
    }
    
    public void doSearch(final String searchstr) throws UnsupportedEncodingException {
        if(null == conn) {
            try {
                if(!new File(dbFileName).exists()) {
                    JOptionPane.showMessageDialog(this, "Error: File " + dbFileName + " not found");
                    return;
                } else {
                    conn = connectDb();
                }
            } catch(SQLException ex) {
                ex.printStackTrace();
            }

        }
        String delsql = "DELETE FROM searchvals WHERE 1";
        String inssql = "INSERT OR IGNORE INTO searchvals(searchval) VALUES (?)";
        String searchsql = "SELECT * FROM dosearch ORDER BY found DESC, matchlen DESC LIMIT 50";
        
        // System.out.println(searchstr + " : " + asciistr);
        
        cancelCurrentSearch = false;
        
        HashMap<String, String> searchByAscii = new HashMap<>();

        Pattern pat = Pattern.compile("(?<y>\\d{4})\\-(?<m>\\d{2})\\-(?<d>\\d{2})");
        Matcher mat = pat.matcher(searchstr);
        if(mat.find()) {
            int y = Integer.valueOf(mat.group("y"));
            int m = Integer.valueOf(mat.group("m"));
            int d = Integer.valueOf(mat.group("d"));

            String[] fmts = {
                String.format("%d%d%d", y, m, d),
                String.format("%d%d%d", d, m, y),
                String.format("%d%d%d", m, d, y),
                String.format("%d%02d%02d", y, m, d),
                String.format("%02d%02d%d", d, m, y),
                String.format("%02d%02d%d", m, d, y)
            };
            for(String s : fmts) {
                searchByAscii.put(s, s);
            }
        } else {
            // Search upper and lowercase variant on input
            // in various encodings
            
            searchByAscii.put(searchstr, searchstr);
            
            final String searchstr_upper = searchstr.toUpperCase();
            final String searchstr_lower = searchstr.toLowerCase();
            List<String> selectedEncodings = new ArrayList<>();
            for(int i : encodingList.getSelectedIndices()) {
                selectedEncodings.add(encodingList.getModel().getElementAt(i));
            }
            for(String encoding : selectedEncodings) {
                StringBuilder sb = new StringBuilder();
                StringBuilder sb_upper = new StringBuilder();
                StringBuilder sb_lower = new StringBuilder();
                
                byte[] bytes = searchstr.getBytes(encoding);
                byte[] bytes_upper = searchstr_upper.getBytes(encoding);
                byte[] bytes_lower = searchstr_lower.getBytes(encoding);
                
                for(int i = 0; i < searchstr.length(); i++) {
                    sb.append(String.format("%d", 0xff & bytes[i]));
                    sb_upper.append(String.format("%d", 0xff & bytes_upper[i]));
                    sb_lower.append(String.format("%d", 0xff & bytes_lower[i]));
                }
                
                searchByAscii.put(sb.toString(), searchstr + " (" + encoding + ")");
                searchByAscii.put(sb_upper.toString(), searchstr_upper + " (" + encoding + ")");
                searchByAscii.put(sb_lower.toString(), searchstr_lower + " (" + encoding + ")");
            }
        }
        
        DefaultListModel m = new DefaultListModel<String>();
        for(String s : searchByAscii.keySet()) {
            m.addElement(s);
        }
        searchTexts.setModel(m);
        
        String[] columns = {"searchstr", "q", "found", "t_sofar", "matchlen", "rownum", "page"};
        
        try(Statement stmt = conn.createStatement();
                PreparedStatement insstmt = conn.prepareStatement(inssql)) {
            stmt.execute(delsql);
            
            for(String s : searchByAscii.keySet()) {
                insstmt.setString(1, s);
                insstmt.executeUpdate();
            }
            
            DefaultTableModel model = new DefaultTableModel(columns, 0);
            try(ResultSet rs = stmt.executeQuery(searchsql)) {
                while(rs.next()) {
                    String[] row = new String[columns.length];
                    for(int i = 0; i < columns.length; i++) {
                        if(columns[i].equals("searchstr")) {
                            row[i] = searchByAscii.get(rs.getString("q"));
                        } else {
                            row[i] = rs.getString(columns[i]);
                        }
                    }
                    model.addRow(row);
                }
            }
            resultTbl.setModel(model);
            searchProgress.setValue(searchProgress.getMaximum());
            conn.commit();
        } catch(SQLException ex) {
            if(!ex.getMessage().contains("interrupt")) {
                ex.printStackTrace();
            }
        }
    }
    
    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {
        java.awt.GridBagConstraints gridBagConstraints;

        jPanel1 = new javax.swing.JPanel();
        jLabel2 = new javax.swing.JLabel();
        searchText = new javax.swing.JTextField();
        jLabel3 = new javax.swing.JLabel();
        searchProgress = new javax.swing.JProgressBar();
        jPanel2 = new javax.swing.JPanel();
        jLabel1 = new javax.swing.JLabel();
        jScrollPane3 = new javax.swing.JScrollPane();
        encodingList = new javax.swing.JList<>();
        jLabel4 = new javax.swing.JLabel();
        jScrollPane2 = new javax.swing.JScrollPane();
        searchTexts = new javax.swing.JList<>();
        jScrollPane1 = new javax.swing.JScrollPane();
        resultTbl = new javax.swing.JTable();

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setTitle("Searching Digits");
        setPreferredSize(new java.awt.Dimension(1024, 768));
        getContentPane().setLayout(new java.awt.GridBagLayout());

        jPanel1.setLayout(new java.awt.GridBagLayout());

        jLabel2.setText("Search Text:");
        jPanel1.add(jLabel2, new java.awt.GridBagConstraints());

        searchText.setText("Search");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(6, 6, 6, 6);
        jPanel1.add(searchText, gridBagConstraints);

        jLabel3.setText("Format YYYY-MM-DD for dates");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        jPanel1.add(jLabel3, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.HORIZONTAL;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(0, 9, 0, 9);
        getContentPane().add(jPanel1, gridBagConstraints);

        searchProgress.setMaximum(200);
        searchProgress.setStringPainted(true);
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        getContentPane().add(searchProgress, gridBagConstraints);

        jPanel2.setLayout(new java.awt.GridBagLayout());

        jLabel1.setText("Encodings");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        jPanel2.add(jLabel1, gridBagConstraints);

        encodingList.setModel(new javax.swing.AbstractListModel<String>() {
            String[] strings = { "US-ASCII" };
            public int getSize() { return strings.length; }
            public String getElementAt(int i) { return strings[i]; }
        });
        jScrollPane3.setViewportView(encodingList);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 0.1;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        jPanel2.add(jScrollPane3, gridBagConstraints);

        jLabel4.setText("Searching For:");
        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        jPanel2.add(jLabel4, gridBagConstraints);

        searchTexts.setModel(new javax.swing.AbstractListModel<String>() {
            String[] strings = { "Item 1", "Item 2", "Item 3", "Item 4", "Item 5" };
            public int getSize() { return strings.length; }
            public String getElementAt(int i) { return strings[i]; }
        });
        jScrollPane2.setViewportView(searchTexts);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(2, 2, 2, 2);
        jPanel2.add(jScrollPane2, gridBagConstraints);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.fill = java.awt.GridBagConstraints.VERTICAL;
        gridBagConstraints.weighty = 1.0;
        getContentPane().add(jPanel2, gridBagConstraints);

        resultTbl.setModel(new javax.swing.table.DefaultTableModel(
            new Object [][] {
                {},
                {},
                {},
                {}
            },
            new String [] {

            }
        ));
        jScrollPane1.setViewportView(resultTbl);

        gridBagConstraints = new java.awt.GridBagConstraints();
        gridBagConstraints.gridwidth = java.awt.GridBagConstraints.REMAINDER;
        gridBagConstraints.fill = java.awt.GridBagConstraints.BOTH;
        gridBagConstraints.weightx = 1.0;
        gridBagConstraints.weighty = 1.0;
        gridBagConstraints.insets = new java.awt.Insets(6, 6, 6, 6);
        getContentPane().add(jScrollPane1, gridBagConstraints);

        pack();
    }// </editor-fold>//GEN-END:initComponents

    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException ex) {
            java.util.logging.Logger.getLogger(MDSearchForm.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (InstantiationException ex) {
            java.util.logging.Logger.getLogger(MDSearchForm.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (IllegalAccessException ex) {
            java.util.logging.Logger.getLogger(MDSearchForm.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        } catch (javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(MDSearchForm.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            public void run() {
                MDSearchForm mds = new MDSearchForm();
                mds.setVisible(true);
                mds.setSearch("RAND");
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JList<String> encodingList;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanel2;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JScrollPane jScrollPane2;
    private javax.swing.JScrollPane jScrollPane3;
    private javax.swing.JTable resultTbl;
    private javax.swing.JProgressBar searchProgress;
    private javax.swing.JTextField searchText;
    private javax.swing.JList<String> searchTexts;
    // End of variables declaration//GEN-END:variables
}
