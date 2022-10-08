import java.io.File;
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

            FileSearcher fileSearcher = new FileSearcher();

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

            HashMap<String, Table> tables = fileSearcher.getTables();
            Set<String> tableNames = tables.keySet();
            System.out.println("Tables found:");
            for (String name: tableNames) {
                System.out.println(name);
            }

        }
        catch(Exception e) {
            e.printStackTrace();
        }
    }
}
