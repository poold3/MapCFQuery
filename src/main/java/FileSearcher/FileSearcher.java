package FileSearcher;

import java.io.File;
import java.io.IOException;
import java.util.*;

import MyScanner.*;
import Table.Table;

import dev.failsafe.internal.util.Assert;
import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.By;
import org.openqa.selenium.chrome.ChromeOptions;

import javax.lang.model.element.Element;

public class FileSearcher {
    private HashMap<String, Table> tables;
    private WebDriver driver;

    public FileSearcher() {
        this.tables = new HashMap<>();
        //Locate chromedriver.exe
        System.setProperty("webdriver.chrome.driver", "C:/Users/poold3/IdeaProjects/MapCFQuery/WebDrivers/chromedriver.exe");

        //Set ChromeOptions
        ChromeOptions options = new ChromeOptions();
        options.addArguments("--start-maximized");
        //options.addArguments("--headless");
        this.driver = new ChromeDriver(options);

        //Open sql parser
        driver.get("https://sql-app.infocruncher.com/");
    }

    public HashMap<String, Table> getTables() {
        return this.tables;
    }

    private List<String> getStringsSeparatedByWhiteSpace(String str) {
        List<String> strings = new ArrayList<>();

        //Separate strings with whitespace
        boolean inWord = false;
        int startString = 0;
        for (int i = 0; i < str.length(); ++i) {
            char c = str.charAt(i);
            if (Character.isWhitespace(c) || i == str.length() - 1) {
                if (inWord) {
                    //Get tableName and add into tables.
                    String newString = str.substring(startString, i + 1).trim();
                    strings.add(newString);
                }
                inWord = false;
            }
            else {
                if (!inWord) {
                    startString = i;
                }
                inWord = true;
            }
        }

        return strings;
    }

    private void waitTimeMilli(long timeMilli) {
        long startTime = System.currentTimeMillis();
        while (System.currentTimeMillis() - startTime < timeMilli) {

        }
    }
    public void search(File fileToSearch) {
        try {
            //Validate fileToRead
            if (!fileToSearch.exists()) {
                throw new IOException(fileToSearch.getAbsolutePath() + " does not exist");
            }
            else if (!fileToSearch.canRead()) {
                throw new IOException("Can't read from " + fileToSearch.getAbsolutePath());
            }

            Scanner mySearcher = new Scanner(fileToSearch);

            //Read from fileToSearch
            int lineNumber = 0;
            int currentQueryLine = 0;
            System.out.println("Reading from " + fileToSearch.getAbsolutePath() + "\n");
            boolean inCFQuery = false;
            boolean inComment = false;
            StringBuilder currentQuery = new StringBuilder();

            while (mySearcher.hasNext()) {
                ++lineNumber;
                StringBuilder line = new StringBuilder(mySearcher.nextLine().toLowerCase());
                if (line.indexOf("<!---") != -1 && line.indexOf("--->") == -1) {
                    inComment = true;
                }
                else if (line.indexOf("--->") != -1) {
                    inComment = false;
                }
                if (!inComment) {
                    if (line.indexOf("<cfquery ") != -1) {
                        inCFQuery = true;
                        currentQuery.setLength(0);
                        currentQuery.append(line).append(" ");
                        currentQueryLine = lineNumber;
                    }
                    else if (inCFQuery && line.indexOf("</cfquery>") != -1) {
                        inCFQuery = false;
                        currentQuery.append(line).append(" ");

                        //Get refinedQuery. Query ready to send to parser.
                        String refinedQuery = MyScanner.cfqueryScanner(currentQuery);

                        //Clear input box. Load in refinedQuery. Click parse button.
                        this.driver.findElement(By.id("input-text")).clear();
                        this.driver.findElement(By.id("input-text")).sendKeys(refinedQuery);
                        this.driver.findElement(By.id("input-button")).click();

                        waitTimeMilli(100);

                        //Wait until results have loaded. Failsafe of 10 seconds.
                        WebElement response = this.driver.findElement(By.id("response"));
                        long startTime = System.currentTimeMillis();
                        boolean tooLong = false;
                        while (response.getAttribute("innerHTML").contains("Parsing query...")) {
                            if (System.currentTimeMillis() - startTime > 10000) {
                                tooLong = true;
                                break;
                            }
                        }

                        waitTimeMilli(100);

                        //Check for errors!
                        if (tooLong) {
                            System.err.println("Parse took too long: '" + refinedQuery + "'. Reading from " + fileToSearch.getAbsolutePath());
                            continue;
                        }

                        String innerResponse = response.getAttribute("innerHTML");
                        if (innerResponse.contains("Oops, I didn't understand that")) {
                            System.err.println("Parse Failed: '" + refinedQuery + "'");
                            System.err.println("\tLine " + currentQueryLine + " in " + fileToSearch.getAbsolutePath());
                            continue;
                        }

                        //Get rows in results
                        List<WebElement> rows = response.findElements(By.tagName("tr"));

                        List<String> tableNames = null;

                        //Iterate through table rows
                        for (WebElement tableRow: rows) {
                            //Get table names. Load into tables
                            if (tableRow.getAttribute("innerHTML").contains("Table names")) {
                                List<WebElement> nameRows = tableRow.findElements(By.tagName("td"));

                                //Get tableNames
                                tableNames = getStringsSeparatedByWhiteSpace(
                                        nameRows.get(1).getAttribute("innerHTML").trim()
                                );

                                for (String tableName: tableNames) {
                                    //Add tableName into tables
                                    if (!this.tables.containsKey(tableName)) {
                                        this.tables.put(tableName, new Table(tableName));
                                    }
                                    //Add fileToSearch into tables
                                    this.tables.get(tableName).addFileLocation(fileToSearch);
                                }
                            }
                            //Get column names. Load into tables.
                            else if (tableNames != null && tableRow.getAttribute("innerHTML").contains("Column names")) {
                                List<WebElement> nameRows = tableRow.findElements(By.tagName("td"));

                                //Get columnNames
                                List<String> columnNames = getStringsSeparatedByWhiteSpace(
                                        nameRows.get(1).getAttribute("innerHTML").trim()
                                );

                                for (String columnName: columnNames) {
                                    if (columnName.contains(".")) {
                                        int separatorIndex = columnName.indexOf(".");
                                        String tableName = columnName.substring(0, separatorIndex);
                                        String refinedColumnName = columnName.substring(separatorIndex + 1);
                                        if (this.tables.containsKey(tableName)) {
                                            this.tables.get(tableName).addColumnUsed(refinedColumnName);
                                        }
                                    }
                                    else {
                                        if (tableNames.size() == 1) {
                                            this.tables.get(tableNames.get(0)).addColumnUsed(columnName);
                                        }
                                        else {
                                            for (String tableName: tableNames) {
                                                this.tables.get(tableName).addPossibleColumnUsed(columnName);
                                            }
                                        }
                                    }
                                }

                            }
                        }
                    }
                    else if (inCFQuery) {
                        currentQuery.append(line).append(" ");
                    }
                }
            }
            mySearcher.close();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }

    public void close() {
        this.driver.quit();
    }
}
