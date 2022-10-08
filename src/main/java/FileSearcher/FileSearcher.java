package FileSearcher;

import java.io.File;
import java.io.IOException;
import java.util.*;

import MyScanner.*;
import Table.Table;

import org.openqa.selenium.NoSuchElementException;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;
import org.openqa.selenium.chrome.ChromeDriver;
import org.openqa.selenium.By;

import javax.lang.model.element.Element;

public class FileSearcher {
    private HashMap<String, Table> tables;

    public FileSearcher() {
        this.tables = new HashMap<>();
    }

    public HashMap<String, Table> getTables() {
        return this.tables;
    }

    public void search(File fileToSearch) {
        try {
            System.setProperty("webdriver.chrome.driver", "C:/Users/poold3/IdeaProjects/MapCFQueryMVN/JARS/chromedriver.exe");
            WebDriver driver = new ChromeDriver();

            driver.get("https://sql-app.infocruncher.com/");
            //Validate fileToRead
            if (!fileToSearch.exists()) {
                throw new IOException(fileToSearch.getAbsolutePath() + " does not exist");
            }
            else if (!fileToSearch.canRead()) {
                throw new IOException("Can't read from " + fileToSearch.getAbsolutePath());
            }

            Scanner mySearcher = new Scanner(fileToSearch);

            int lineNumber = 1;

            System.out.println("Reading from " + fileToSearch.getAbsolutePath() + "\n");
            boolean inCFQuery = false;
            boolean inComment = false;
            StringBuilder currentQuery = new StringBuilder();
            while (mySearcher.hasNext()) {
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
                        currentQuery.append(line);
                    }
                    else if (line.indexOf("</cfquery>") != -1) {
                        inCFQuery = false;
                        currentQuery.append(line);
                        String refinedQuery = MyScanner.cfqueryScanner(currentQuery);

                        driver.findElement(By.id("input-text")).clear();
                        driver.findElement(By.id("input-text")).sendKeys(refinedQuery);
                        driver.findElement(By.id("input-button")).click();

                        //Get rows in results
                        List<WebElement> rows = new ArrayList<>();

                        //Wait until results have loaded
                        while (rows.size() < 3) {
                            rows = driver.findElement(By.id("response")).findElements(By.tagName("tr"));
                        }

                        //Get table names. Load into tables
                        WebElement tableRow = rows.get(1);
                        List<WebElement> nameRows = tableRow.findElements(By.tagName("td"));
                        StringBuilder tableNames = new StringBuilder(nameRows.get(1).getAttribute("innerHTML").trim());
                        while (tableNames.length() > 0) {
                            int endIndex = tableNames.indexOf(" ");
                            String tableName;
                            if (endIndex != -1) {
                                tableName = tableNames.substring(0, endIndex);
                                tableNames.delete(0, endIndex + 1);
                            }
                            else {
                                tableName = tableNames.toString();
                                tableNames.setLength(0);
                            }
                            if (!this.tables.containsKey(tableName)) {
                                this.tables.put(tableName, new Table(tableName));
                            }
                        }

                        //Get column names.
                        WebElement columnRow = rows.get(2);

                        //System.out.println(driver.findElement(By.id("response")).getAttribute("innerHTML"));

                    }
                    else if (inCFQuery) {
                        currentQuery.append(line);
                    }
                }
                lineNumber += 1;
            }
            mySearcher.close();
            driver.quit();
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
