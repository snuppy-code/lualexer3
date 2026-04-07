#[cfg(test)]
mod tests {
    use crate::lexer_types::{Keyword, Lexer, LiteralString, NumericConstant, Span, Symbol, TokenKind};

    #[test]
    fn test_create() {
        let s = "while true abc! J(@ jg2gh";
        let l = Lexer::new(s);

        assert_eq!(l.get_view(), s);
        assert_eq!(l.tokens_len(), 0);
    }

    #[test]
    fn test_simple_whitespace() {
        let s = "   ";
        let mut l = Lexer::new(s);

        l.lex_to_end();
        assert_eq!(l.tokens_len(), 0);
    }

    #[test]
    fn test_simple_keyword() {
        let mut l = Lexer::new("and");
        
        l.lex_to_end();
        let mut i = l.iter_tokens();
        assert_eq!(i.next().unwrap().get_kind(), &TokenKind::Keyword(Keyword::And));
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_simple_symbol() {
        let mut l = Lexer::new("*");
        
        l.lex_to_end();
        let mut i = l.iter_tokens();
        assert_eq!(i.next().unwrap().get_kind(), &TokenKind::Symbol(Symbol::Star));
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_simple_identifier() {
        let mut l = Lexer::new("x y");
        
        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::Identifier);
        assert_eq!(i.next().unwrap().get_span(), Span("x"));
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::Identifier);
        assert_eq!(i.next().unwrap().get_span(), Span("y"));
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_long_identifier() {
        let mut l = Lexer::new("awoifjaw anderthal");
        
        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::Identifier);
        assert_eq!(i.next().unwrap().get_span(), Span("awoifjaw"));
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::Identifier);
        assert_eq!(i.next().unwrap().get_span(), Span("anderthal"));
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_simple_short_string() {
        let s = r#""ab \" c""#;
        let s1 = r#"ab \" c"#;
        let mut l = Lexer::new(s);
        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::LiteralString(LiteralString::UnescapedShort(s1)));
        assert_eq!(i.next().unwrap().get_span(), Span(s));
    }

    #[test]
    fn test_z_short_string_escape() {
        let s = r#""a\z   
b""#;
        let s_unescaped = r#"a\z   
b"#;
        let s_escaped = r#"ab"#;
        let mut l = Lexer::new(s);
        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::LiteralString(LiteralString::UnescapedShort(s_unescaped)));
        assert_eq!(i.peek().unwrap().get_span(), Span(s));
        let lit_str = i.next().unwrap().get_kind().unwrap_literal_string();
        assert_eq!(lit_str.escape(), LiteralString::Escaped(String::from(s_escaped)));
    }

    #[test]
    fn test_complex_short_string_escape() {
        let s = r#""a\z   
\
\n
\u{000000078} \65 \118 \a \" \\\\""#;
        let s_unescaped = r#"a\z   
\
\n
\u{000000078} \65 \118 \a \" \\\\"#;
        let s_escaped = "a\n\n\nx A v \u{7} \" \\\\";
        let mut l = Lexer::new(s);
        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(), &TokenKind::LiteralString(LiteralString::UnescapedShort(s_unescaped)));
        assert_eq!(i.peek().unwrap().get_span(), Span(s));
        let lit_str = i.next().unwrap().get_kind().unwrap_literal_string();
        assert_eq!(lit_str.escape(), LiteralString::Escaped(String::from(s_escaped)));
    }

    #[test]
    fn test_simple_long_string() {
        let s = "[[ abc\nabc]]";
        let s1 = " abc\nabc";
        let mut l = Lexer::new(s);
        
        l.lex_to_end();
        let mut i = l.iter_tokens();
        let a = i.next().unwrap();
        assert_eq!(a.get_kind(),
            &TokenKind::LiteralString(LiteralString::UnescapedLong(s1)));
        assert_eq!(a.get_span(), Span(s));
        assert_eq!(i.next(), None);
    }
    
    #[test]
    fn test_complicated_long_string() {
        let s = "[==[ [abc\nabc] ]==]";
        let s1 = " [abc\nabc] ";
        let mut l = Lexer::new(s);

        l.lex_to_end();
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.peek().unwrap().get_kind(),
            &TokenKind::LiteralString(LiteralString::UnescapedLong(s1)));
        assert_eq!(i.peek().unwrap().get_span(), Span(s));
        assert_eq!(i.next().unwrap().get_kind().get_literal_string().unwrap().escape(),
            LiteralString::Escaped(String::from(s1)));
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_numeric_constants() {
        let s = "0 15 153803 1.3 0. .0 0.0005 0x345 0xff 0xBEBADA 0xA3Fb.F31fAp-14";
        let mut l = Lexer::new(s);
        
        l.lex_to_end();
        dbg!(&l);
        let mut i = l.iter_tokens().peekable();
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(0)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(15)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(153803)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Float(1.3)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Float(0.0)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Float(0.0)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Float(0.0005)));
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(837))); //0x345
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(255))); //0xff
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Integer(12499674))); //0xBEBADA
        // in my testing, lua 5.4 print() only outputs 2.5622527893865, in rust we get an added 48 on there
        // I just assume it is printing differences, this might be incorrect
        assert_eq!(i.next().unwrap().get_kind(),
            &TokenKind::NumericConstant(NumericConstant::Float(2.562252789386548))); //0xA3Fb.F31fAp-14
        assert_eq!(i.next(), None);
    }

    #[test]
    fn test_extensive_lua_example() { // the toy lua program in the string was generated by gemini
        let s = r#"
-- Single-line comment: Testing the bounds of Lua's lexer
--[[ 
  Multi-line comment block.
  We will cover all 22 keywords, various number formats, 
  string boundaries, and Lua 5.3+ operators.
]]

local function extreme_lexer_test(param1, ...)
    ::start_label:: -- A label for the rarely used goto statement

    -- 1. Numbers (Integers, Floats, Hex, Hex-Floats, Scientific)
    local int_val    = 42
    local float_val  = 3.14159265
    local sci_val    = 1.2e-5
    local hex_val    = 0xDEADBEEF
    local hex_float  = 0x1.921fb54442d18p+1 -- e.g., pi in hex-float

    -- 2. Strings (Short, Long, All Escapes)
    -- Covers: \a, \b, \f, \n, \r, \t, \v, \\, and \"
    local str_double = "Basic escapes: bell\a, backspace\b, formfeed\f, newline\n, return\r, tab\t, vtab\v, slash\\\\, d-quote\""
    
    -- Covers: \', \ddd (decimal), \xXX (hex), \u{XXX} (UTF-8), and \z (skip whitespace)
    local str_single = 'Advanced escapes: s-quote\', dec\065, hex\x42, unicode\u{1F600}, and gap\z
                        skipping across newlines.'

    local long_str   = [==[
        Long strings ignore escape sequences like \n.
        The [==[ syntax allows nested [[ ]] blocks inside safely.
    ]==]

    -- 3. Booleans and Nil
    local is_true  = true
    local is_false = false
    local nothing  = nil

    -- 4. Tables, Punctuation, and Variadic arguments
    local complex_table = {
        ["key_string"] = str_double .. str_single, -- Concatenation
                   = { ... },                  -- Variadic expansion
        nested         = int_val + float_val * 2 / 1
    }

    -- 5. Operators (Length, Arithmetic, Bitwise, Relational, Logical)
    local tbl_len    = #complex_table
    local power_mod  = (5 ^ 2) % 4
    local floor_div  = 10 // 3                     -- Lua 5.3+ Floor division
    local bitwise    = (hex_val & 0xFF) | (1 << 4) ~ (int_val >> 1) -- Bitwise ops

    -- 6. Control Structures (If, Elseif, Else, Goto)
    if not is_false and (int_val ~= float_val) then
        ; -- Empty statement (semicolon)
    elseif int_val == 42 or nothing == nil then
        -- Relational (==, ~=, <, >, <=, >=) all follow similar lexing rules
        local dummy = float_val >= sci_val
    else
        goto start_label
    end

    -- 7. Loops (Numeric For, Generic For, While, Repeat-Until)
    for i = 1, 10, 2 do
        if i > 5 then break end
    end

    for k, v in pairs(complex_table) do
        -- Assuming 'pairs' is in the global environment
    end

    local counter = 0
    while counter <= 5 do
        counter = counter + 1
    end

    repeat
        counter = counter - 1
    until counter < 0

    -- 8. Object-oriented colon syntax
    complex_table:dummy_method()

    -- 9. Anonymous function return
    return function() return tbl_len end
end
        "#;
        let mut l = Lexer::new(s);

        l.lex_to_end();
        dbg!(l);
    }
}