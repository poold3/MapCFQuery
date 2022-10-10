package MyScanner;

public class Token {
    private String value;
    private TOKEN_TYPES type;

    public enum TOKEN_TYPES {
        BeginTag,
        EndTag,
        Logic,
        Tag,
        LeftParen,
        RightParen,
        Period,
        Comma,
        SemiColon,
        Is_Not_Null,
        Is_Null,
        Order_By,
        Select,
        Delete,
        Delete_From,
        Inner_Join,
        Join,
        On,
        Star,
        As,
        Like,
        From,
        Where,
        Update,
        Set,
        Insert,
        Merge,
        Values,
        And,
        Or,
        String,
        Identifier,
        Number,
        Fetch,
        First,
        Rows,
        Columns,
        Only,
        White_Space,
        ColdFusion_Var,
        None
    }

    public Token(TOKEN_TYPES type, String value) {
        this.type = type;
        this.value = value;
    }

    public TOKEN_TYPES getType() {
        return this.type;
    }

    public String getValue() {
        return this.value;
    }
}
