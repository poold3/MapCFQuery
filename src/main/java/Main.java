import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.*;

import FileSearcher.FileSearcher;
import Table.Table;

public class Main {

    private static final Set<String> VALID_FILE_TYPES = new HashSet<>(Arrays.asList(".cfm", ".cfc"));

    private static String getFileType(File file) {
        String fileName = file.getName();
        return fileName.length() >= 4 ? fileName.substring(fileName.length() - 4) : "none";
    }
    private static void recursiveFileFinder(File[] files, FileSearcher fileSearcher) {
        for (File file: files) {
            if (file.isDirectory()) {
                recursiveFileFinder(Objects.requireNonNull(file.listFiles()), fileSearcher);
            }
            else {
                //Verify that file is a valid type
                if (VALID_FILE_TYPES.contains(getFileType(file))) {
                    //Read from file
                    fileSearcher.search(file);
                }
            }
        }
    }

    public static void main(String[] args) {
        FileSearcher fileSearcher = new FileSearcher();
        try {
            if (args.length < 2) {
                throw new IllegalArgumentException("Incorrect number of command-line arguments.");
            }

            //Get mapDirectory and perform validation
            File mapDirectory = new File(args[0]);
            if (!mapDirectory.exists() || !mapDirectory.isDirectory()) {
                throw new IllegalArgumentException("Map Directory (" + mapDirectory.getAbsolutePath() + ") either " +
                        "doesn't exist or is not a directory.");
            }

            File newMapFile = new File(mapDirectory.getAbsolutePath() + "/Summary.txt");
            if (newMapFile.exists() && !newMapFile.delete()) {
                throw new IOException("Unable to delete existing Summary.txt file.");
            }
            else if (!newMapFile.createNewFile()) {
                throw new IOException("Unable to create Summary.txt");
            }

            //Loop through rest of args[] to get locations of files/directories to search
            for (int i = 1; i < args.length; ++i) {
                try {
                    //Get file/directory and validate
                    File searchHere = new File(args[i]);
                    if (!searchHere.exists()) {
                        throw new IllegalArgumentException(searchHere.getAbsolutePath() + " does not exist");
                    }

                    if (searchHere.isDirectory()) {
                        recursiveFileFinder(Objects.requireNonNull(searchHere.listFiles()), fileSearcher);
                    }
                    else {
                        //Verify that file is a valid type
                        if (VALID_FILE_TYPES.contains(getFileType(searchHere))) {
                            //Read from file and write to newMapFile
                            fileSearcher.search(searchHere);
                        }
                    }

                }
                catch (Exception e) {
                    e.printStackTrace();
                }
            }

            //Write tables to newMapFile
            Collection<Table> tables = fileSearcher.getTables().values();
            try (FileWriter myWriter = new FileWriter(newMapFile)) {
                //List files and directories searched
                myWriter.write("Tables found within:\n");
                for (int i = 1; i < args.length; ++i) {
                    myWriter.write("\t" + args[i] + "\n");
                }
                myWriter.write("\n");

                //List tables
                for (Table table: tables) {
                    myWriter.write("Table: " + table.getName() + "\n");

                    myWriter.write("Columns Used: \n");
                    SortedSet<String> columnsUsed = table.getColumnsUsed();
                    for (String column: columnsUsed) {
                        myWriter.write("\t" + column + "\n");
                    }

                    myWriter.write("Possible Columns Used: \n");
                    SortedSet<String> possibleColumnsUsed = table.getPossibleColumnsUsed();
                    for (String column: possibleColumnsUsed) {
                        myWriter.write("\t" + column + "\n");
                    }

                    myWriter.write("Locations: \n");
                    SortedSet<String> locations = table.getFileLocations();
                    for (String location: locations) {
                        myWriter.write("\t" + location + "\n");
                    }

                    myWriter.write("\n");
                }
            }
            catch (IOException e) {
                e.printStackTrace();
                throw e;
            }
        }
        catch(Exception e) {
            e.printStackTrace();
        }
        finally {
            fileSearcher.close();
        }
    }
}
