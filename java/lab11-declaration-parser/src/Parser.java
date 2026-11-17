import java.util.ArrayList;
import java.util.List;

public class Parser {//список токенв из лексы
    private final List<Token> tokens;
    private int pos = 0;//текущ поз в списке
    private final List<String> rules = new ArrayList<>();//журнал разбора

    public Parser(List<Token> tokens) { //принимает список токенов
        this.tokens = tokens;
    }

    private Token sym() {
        if (pos >= tokens.size()) return new Token("EOF", "", -1, -1);
        return tokens.get(pos);
    }//возвращаем текущий токен, если вышел за границу - еоф

    private void next() {
        pos++;
    }
    //выбрасываю искл с коорд ошибки
    private void error(Token t) {
        throw new RuntimeException("syntax error at (" + t.line + ", " + t.col + ")");
    }

    public void parseDecl() {
        rules.add("<Decl> ::= <Type> <Ptr>"); //тип и указатель птр
        parseType();
        parsePtr();
        if (!sym().type.equals("EOF")) {//лишние символы
            error(sym());
        }
    }
    //int or float
    private void parseType() {
        Token t = sym();
        if (t.type.equals("IDENT") && (t.value.equals("int") || t.value.equals("float"))) {
            rules.add("<Type> ::= " + t.value);
            next();
        } else {
            error(t);
        }
    }
    //<Ptr> — может быть либо * <Ptr>, либо <Prim> <Dims>
    private void parsePtr() {
        Token t = sym();
        if (t.type.equals("*")) {
            rules.add("<Ptr> ::= * <Ptr>");
            next();
            parsePtr();
        } else {
            rules.add("<Ptr> ::= <Prim> <Dims>");
            parsePrim();
            parseDims();
        }
    }
    //<Prim> — либо IDENT, либо (<Ptr>)
    private void parsePrim() {
        Token t = sym();
        if (t.type.equals("IDENT")) {
            rules.add("<Prim> ::= IDENT");
            next();
        } else if (t.type.equals("(")) {
            rules.add("<Prim> ::= ( <Ptr> )");
            next();
            parsePtr();
            t = sym();
            if (!t.type.equals(")")) error(t);
            next();
        } else {
            error(t);
        }
    }
    // 0 или число в диме
    private void parseDims() {
        Token t = sym();
        if (t.type.equals("[")) {
            rules.add("<Dims> ::= [ NUMBER ] <Dims>");
            next();
            t = sym();
            if (!t.type.equals("NUMBER")) error(t);
            next();
            t = sym();
            if (!t.type.equals("]")) error(t);
            next();
            parseDims();
        } else {
            rules.add("<Dims> ::= ε");
        }
    }

    public List<String> getRules() {
        return rules;
    }
}