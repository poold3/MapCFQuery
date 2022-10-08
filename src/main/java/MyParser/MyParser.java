package MyParser;


import MyScanner.Token;
import Table.Table;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.SortedSet;
import java.util.TreeSet;

public class MyParser {
    private static String match(ArrayList<Token> tokens, Token.TOKEN_TYPES type) {
        if (tokens.size() > 0 && tokens.get(0).getType() == type) {
            String value = new String(tokens.get(0).getValue());
            tokens.remove(0);
            return value;
        }
        else {
            throw new IllegalArgumentException("Invalid Token Order. Expected: " + type + ". Received: " + tokens.get(0).getType());
        }
    }

    private static void updateTables(HashMap<String, Table> tables, SortedSet<String> columnsFound, HashMap<String, SortedSet<String>> tablesFound) {

    }
    public static void parseTokens(ArrayList<Token> tokens, HashMap<String, Table> tables, File fileBeingSearched) {
        try {
            while (tokens.size() > 0) {
                //Match BeginTag
                match(tokens, Token.TOKEN_TYPES.BeginTag);

                SortedSet<String> columnsFound = new TreeSet<>();
                ArrayList<SortedSet<String>> tablesFound = new ArrayList<>();

                if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Select) {
                    //Match Select
                    match(tokens, Token.TOKEN_TYPES.Select);

                    //Get selected columns
                    while (tokens.get(0).getType() != Token.TOKEN_TYPES.From) {
                        columnsFound.add(match(tokens, Token.TOKEN_TYPES.Identifier));
                        if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.As) {
                            match(tokens, Token.TOKEN_TYPES.As);
                            match(tokens, Token.TOKEN_TYPES.Identifier);
                        }
                        if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Comma) {
                            match(tokens, Token.TOKEN_TYPES.Comma);
                        }
                    }

                    //Match From
                    match(tokens, Token.TOKEN_TYPES.From);

                    while (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Where) {
                        //Get table name
                        String tableName = match(tokens, Token.TOKEN_TYPES.Identifier);

                        //Create new map entry if necessary
//                        if (!tablesFound.containsKey(tableName)) {
//                            tablesFound.put(tableName, new TreeSet<>());
//                        }

                        //Add table name to tablesFound
                        //tablesFound.get(tableName).add(tableName);

                        //We found a second identifier for tableName
                        if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Identifier) {
                            //tablesFound.get(tableName).add(match(tokens, Token.TOKEN_TYPES.Identifier));
                        }

                        //On command for JOINs
                        if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.On) {
                            match(tokens, Token.TOKEN_TYPES.On);
                            columnsFound.add(match(tokens, Token.TOKEN_TYPES.Identifier));
                            match(tokens, Token.TOKEN_TYPES.Logic);
                            columnsFound.add(match(tokens, Token.TOKEN_TYPES.Identifier));
                        }

                        //INNER JOIN and JOIN
                        if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Inner_Join) {
                            match(tokens, Token.TOKEN_TYPES.Inner_Join);
                        }
                        else if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Join) {
                            match(tokens, Token.TOKEN_TYPES.Inner_Join);
                        }
                    }

                    match(tokens, Token.TOKEN_TYPES.Where);
                    while (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.EndTag) {
                        columnsFound.add(match(tokens, Token.TOKEN_TYPES.Identifier));
                        if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Is_Not_Null) {
                            match(tokens, Token.TOKEN_TYPES.Is_Not_Null);
                        }
                        else if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Is_Null) {
                            match(tokens, Token.TOKEN_TYPES.Is_Null);
                        }
                        else if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Logic) {
                            match(tokens, Token.TOKEN_TYPES.Logic);
                            if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Number) {
                                match(tokens, Token.TOKEN_TYPES.Number);
                            }
                            else if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.String) {
                                match(tokens, Token.TOKEN_TYPES.String);
                            }
                            else if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.Identifier) {
                                match(tokens, Token.TOKEN_TYPES.Identifier);
                            }
                        }
                        else if (tokens.size() > 0 && tokens.get(0).getType() != Token.TOKEN_TYPES.EndTag) {
                            match(tokens, tokens.get(0).getType());
                        }
                    }
                }
                else if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Update) {

                }
                else if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Insert) {

                }
                else if (tokens.size() > 0 && tokens.get(0).getType() == Token.TOKEN_TYPES.Delete) {

                }
                match(tokens, Token.TOKEN_TYPES.EndTag);
                //updateTables(tables, columnsFound, tablesFound);
            }
        }
        catch (Exception e) {
            System.err.println("Error while reading " + fileBeingSearched.getAbsolutePath());
            e.printStackTrace();
        }
    }
}
