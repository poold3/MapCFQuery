package MyScanner;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;

public class MyScanner {

    public static HashSet<Token.TOKEN_TYPES> illegalTokens = new HashSet<>(Arrays.asList(Token.TOKEN_TYPES.None,
            Token.TOKEN_TYPES.Tag, Token.TOKEN_TYPES.BeginTag, Token.TOKEN_TYPES.EndTag, Token.TOKEN_TYPES.None));

    private static int getTagLength(StringBuilder cfquery) {
        int length = 0;
        int tagCount = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (cfquery.charAt(i) == '<') {
                tagCount += 1;
            }
            else if (cfquery.charAt(i) == '>') {
                tagCount -= 1;
            }
            if (tagCount == 0) {
                length = i + 1;
                break;
            }
        }
        return length;
    }

    private static int getIdentifierLength(StringBuilder cfquery) {
        int length = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (cfquery.substring(i, i + 1).matches("[a-z0-9-_#.*]")) {
                length += 1;
            }
            else {
                break;
            }
        }
        return length;
    }

    private static int getColdFusionVarLength(StringBuilder cfquery) {
        int length = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (cfquery.charAt(i) != '#') {
                length += 1;
            }
            else {
                break;
            }
        }
        return length + 1;
    }

    private static int getStringLength(StringBuilder cfquery) {
        char stringType = cfquery.charAt(0);
        int length = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (cfquery.charAt(i) != stringType) {
                length += 1;
            }
            else if (cfquery.charAt(i) == stringType && cfquery.charAt(i - 1) == '\\') {
                length += 1;
            }
            else {
                break;
            }
        }
        return length + 1;
    }

    private static int getNumberLength(StringBuilder cfquery) {
        int length = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (cfquery.substring(i, i + 1).matches("[0-9]")) {
                length += 1;
            }
            else {
                break;
            }
        }
        return length;
    }

    private static int getWhiteSpaceLength(StringBuilder cfquery) {
        int length = 1;
        for (int i = 1; i < cfquery.length(); ++i) {
            if (Character.isWhitespace(cfquery.charAt(i))) {
                length += 1;
            }
            else {
                break;
            }
        }
        return length;
    }

    public static String cfqueryScanner(StringBuilder cfquery) {
        StringBuilder refinedQuery = new StringBuilder();
        Token.TOKEN_TYPES type;
        Token.TOKEN_TYPES previousType = null;
        int length;
        while(cfquery.length() > 0) {
            if (cfquery.length() >= 9 && cfquery.substring(0, 9).equals("<cfquery ")) {
                length = getTagLength(cfquery);
                type = Token.TOKEN_TYPES.BeginTag;
            }
            else if (cfquery.length() >= 10 && cfquery.substring(0, 10).equals("</cfquery>")) {
                length = 10;
                type = Token.TOKEN_TYPES.EndTag;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0,1).equals("=")) {
                length = 1;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0,3).equals(" < ")) {
                length = 3;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0,3).equals(" > ")) {
                length = 3;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" <= ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" =< ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" >= ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" => ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" != ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0,4).equals(" <> ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Logic;
            }
            else if (cfquery.length() >= 2 && cfquery.substring(0,2).matches("<[a-z/]")) {
                length = getTagLength(cfquery);
                type = Token.TOKEN_TYPES.Tag;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == '(') {
                length = 1;
                type = Token.TOKEN_TYPES.LeftParen;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == ')') {
                length = 1;
                type = Token.TOKEN_TYPES.RightParen;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == '.') {
                length = 1;
                type = Token.TOKEN_TYPES.Period;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == ',') {
                length = 1;
                type = Token.TOKEN_TYPES.Comma;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == ';') {
                length = 1;
                type = Token.TOKEN_TYPES.SemiColon;
            }
            else if (cfquery.length() >= 11 && cfquery.substring(0, 11).equals("is not null")) {
                length = 11;
                type = Token.TOKEN_TYPES.Is_Not_Null;
            }
            else if (cfquery.length() >= 7 && cfquery.substring(0, 7).equals("is null")) {
                length = 7;
                type = Token.TOKEN_TYPES.Is_Null;
            }
            else if (cfquery.length() >= 8 && cfquery.substring(0, 8).equals("order by")) {
                length = 8;
                type = Token.TOKEN_TYPES.Order_By;
            }
            else if (cfquery.length() >= 6 && cfquery.substring(0, 6).equals("select")) {
                length = 6;
                type = Token.TOKEN_TYPES.Select;
            }
            else if (cfquery.length() >= 11 && cfquery.substring(0, 11).equals("delete from")) {
                length = 11;
                type = Token.TOKEN_TYPES.Delete_From;
            }
            else if (cfquery.length() >= 7 && cfquery.substring(0, 7).equals("delete ")) {
                length = 6;
                type = Token.TOKEN_TYPES.Delete;
            }
            else if (cfquery.length() >= 10 && cfquery.substring(0, 10).equals("inner join")) {
                length = 10;
                type = Token.TOKEN_TYPES.Inner_Join;
            }
            else if (cfquery.length() >= 5 && cfquery.substring(0, 5).equals("join ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Join;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0, 3).equals("on ")) {
                length = 2;
                type = Token.TOKEN_TYPES.On;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0, 1).equals("*")) {
                length = 1;
                type = Token.TOKEN_TYPES.Star;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0, 3).equals("as ")) {
                length = 2;
                type = Token.TOKEN_TYPES.As;
            }
            else if (cfquery.length() >= 5 && cfquery.substring(0, 5).equals("like ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Like;
            }
            else if (cfquery.length() >= 4 && cfquery.substring(0, 4).equals("from")) {
                length = 4;
                type = Token.TOKEN_TYPES.From;
            }
            else if (cfquery.length() >= 5 && cfquery.substring(0, 5).equals("where")) {
                length = 5;
                type = Token.TOKEN_TYPES.Where;
            }
            else if (cfquery.length() >= 6 && cfquery.substring(0, 6).equals("update")) {
                length = 6;
                type = Token.TOKEN_TYPES.Update;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0, 3).equals("set")) {
                length = 3;
                type = Token.TOKEN_TYPES.Set;
            }
            else if (cfquery.length() >= 11 && cfquery.substring(0, 11).equals("insert into")) {
                length = 11;
                type = Token.TOKEN_TYPES.Insert;
            }
            else if (cfquery.length() >= 10 && cfquery.substring(0, 10).equals("merge into")) {
                length = 10;
                type = Token.TOKEN_TYPES.Merge;
            }
            else if (cfquery.length() >= 6 && cfquery.substring(0, 6).equals("values")) {
                cfquery.setLength(6);
                length = 6;
                type = Token.TOKEN_TYPES.Values;
            }
            else if (cfquery.length() >= 3 && cfquery.substring(0, 3).equals("and")) {
                length = 3;
                type = Token.TOKEN_TYPES.And;
            }
            else if (cfquery.length() >= 2 && cfquery.substring(0, 2).equals("or")) {
                length = 2;
                type = Token.TOKEN_TYPES.Or;
            }
            else if (cfquery.length() >= 6 && cfquery.substring(0, 6).equals("fetch ")) {
                length = 5;
                type = Token.TOKEN_TYPES.Fetch;
            }
            else if (cfquery.length() >= 6 && cfquery.substring(0, 6).equals("first ")) {
                length = 5;
                type = Token.TOKEN_TYPES.First;
            }
            else if (cfquery.length() >= 5 && cfquery.substring(0, 5).equals("rows ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Rows;
            }
            else if (cfquery.length() >= 8 && cfquery.substring(0, 8).equals("columns ")) {
                length = 7;
                type = Token.TOKEN_TYPES.Columns;
            }
            else if (cfquery.length() >= 5 && cfquery.substring(0, 5).equals("only ")) {
                length = 4;
                type = Token.TOKEN_TYPES.Only;
            }
            else if (cfquery.length() >= 1 && cfquery.charAt(0) == '\'' || cfquery.charAt(0) == '"') {
                length = getStringLength(cfquery);
                type = Token.TOKEN_TYPES.String;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0, 1).matches("[a-z-]")) {
                length = getIdentifierLength(cfquery);
                type = Token.TOKEN_TYPES.Identifier;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0, 1).matches("[#]")) {
                length = getColdFusionVarLength(cfquery);
                type = Token.TOKEN_TYPES.ColdFusion_Var;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0, 1).matches("[0-9]")) {
                length = getNumberLength(cfquery);
                type = Token.TOKEN_TYPES.Number;
            }
            else if (cfquery.length() >= 1 && cfquery.substring(0, 1).trim().equals("")) {
                length = getWhiteSpaceLength(cfquery);
                type = Token.TOKEN_TYPES.White_Space;
            }
            else {
                length = 1;
                type = Token.TOKEN_TYPES.None;
            }

            if (!illegalTokens.contains(type)) {
                //Wrap all identifiers with ## as a string. Replace ## as cfvar.
                if (cfquery.substring(0, length).matches(".*#.*#.*")) {
                    StringBuilder temp = new StringBuilder(cfquery.substring(0, length));
                    int startIndex = temp.indexOf("#");
                    int endIndex = temp.indexOf("#", startIndex + 1);

                    temp.replace(startIndex, endIndex + 1, "cfvar_");

                    if (!(previousType == Token.TOKEN_TYPES.From || previousType == Token.TOKEN_TYPES.Update ||
                            previousType == Token.TOKEN_TYPES.Delete || previousType == Token.TOKEN_TYPES.Insert ||
                            previousType == Token.TOKEN_TYPES.Join || previousType == Token.TOKEN_TYPES.Inner_Join ||
                            previousType == Token.TOKEN_TYPES.Order_By || previousType == Token.TOKEN_TYPES.Merge)) {
                        if (type == Token.TOKEN_TYPES.Identifier || type == Token.TOKEN_TYPES.ColdFusion_Var) {
                            refinedQuery.append("'");
                            refinedQuery.append(temp);
                            refinedQuery.append("'");
                        }
                        else {
                            refinedQuery.append(temp);
                        }

                    }
                    else {
                        refinedQuery.append(temp);
                    }
                }
                else if (type == Token.TOKEN_TYPES.Delete_From || type == Token.TOKEN_TYPES.Delete) {
                    refinedQuery.append("select from");
                }
                else if (type == Token.TOKEN_TYPES.Merge) {
                    refinedQuery.append("insert into");
                }
                else if (type == Token.TOKEN_TYPES.White_Space) {
                    refinedQuery.append(" ");
                }
                else {
                    refinedQuery.append(cfquery.substring(0, length));
                }
            }
            if (type != Token.TOKEN_TYPES.None && type != Token.TOKEN_TYPES.White_Space) {
                previousType = type;
            }
            cfquery.delete(0, length);
        }

        //Replace all double quotes with single quotes
        return refinedQuery.toString().replaceAll("\"", "'");
    }
}
