package Table;

import java.io.File;
import java.util.SortedSet;
import java.util.TreeSet;

public class Table {
    private final String name;
    private final SortedSet<String> columnsUsed;
    private final SortedSet<String> possibleColumnsUsed;
    private final SortedSet<String> fileLocations;

    public Table(String name) {
        this.name = name;
        this.columnsUsed = new TreeSet<>();
        this.possibleColumnsUsed = new TreeSet<>();
        this.fileLocations = new TreeSet<>();
    }

    public String getName() {
        return this.name;
    }

    public SortedSet<String> getColumnsUsed() {
        return this.columnsUsed;
    }

    public SortedSet<String> getPossibleColumnsUsed() {
        return this.possibleColumnsUsed;
    }
    public void addColumnUsed(String columnName) {
        this.columnsUsed.add(columnName);
        this.possibleColumnsUsed.remove(columnName);
    }

    public void addPossibleColumnUsed(String columnName) {
        if (!this.columnsUsed.contains(columnName)) {
            this.possibleColumnsUsed.add(columnName);
        }
    }

    public SortedSet<String> getFileLocations() {
        return this.fileLocations;
    }

    public void addFileLocation(File file) {
        this.fileLocations.add(file.getAbsolutePath());
    }
}
