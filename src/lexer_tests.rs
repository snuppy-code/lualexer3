#[cfg(test)]
mod tests {
    use crate::lexer_types::{Keyword, Lexer, Span, Symbol, TokenKind};

    #[test]
    fn test_create() {
        let a_input = "while true";        
        let a = Lexer::new(a_input);

        assert_eq!(a.get_internal_view(), a_input);
        assert_eq!(a.get_internal_lexed().len(), 0);
    }

    #[test]
    fn test_simple_whitespace() {
        let mut a = Lexer::new("   ");
        assert_eq!(a.get_internal_view(), "   ");
        assert_eq!(a.get_internal_lexed().len(), 0);
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 0);
    }

    #[test]
    fn test_simple_keyword() {
        let mut a = Lexer::new("and");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 1);
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::Keyword(Keyword::And));
    }

    #[test]
    fn test_simple_symbol() {
        let mut a = Lexer::new("*");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::Symbol(Symbol::Star));
    }

    #[test]
    fn test_simple_identifier() {
        let mut a = Lexer::new("x y");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 2);
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::Identifier);
        assert_eq!(a.get_internal_lexed()[0].get_span(), Span("x"));
        assert_eq!(a.get_internal_lexed()[1].get_kind(), &TokenKind::Identifier);
        assert_eq!(a.get_internal_lexed()[1].get_span(), Span("y"));
    }

    #[test]
    fn test_long_identifier() {
        let mut a = Lexer::new("awoifjaw anderthal");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");

        let lexed = a.get_internal_lexed();
        assert_eq!(lexed.len(), 2);

        assert_eq!(lexed[0].get_kind(), &TokenKind::Identifier);
        assert_eq!(lexed[0].get_span(), Span("awoifjaw"));
        assert_eq!(lexed[1].get_kind(), &TokenKind::Identifier);
        assert_eq!(lexed[1].get_span(), Span("anderthal"));
    }

    #[test]
    fn test_simple_short_string() {
        let mut a = Lexer::new(r#""ab  c""#);
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 1);
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::LiteralString("ab  c"));
        assert_eq!(a.get_internal_lexed()[0].get_span(), Span(r#""ab  c""#));
    }

    #[test]
    fn test_simple_long_string() {
        let mut a = Lexer::new("[[ abc\nabc]]");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 1);
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::LiteralString(" abc\nabc"));
        assert_eq!(a.get_internal_lexed()[0].get_span(), Span("[[ abc\nabc]]"));
    }
    
    #[test]
    fn test_complicated_long_string() {
        let mut a = Lexer::new("[==[ [abc\nabc] ]==]");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        assert_eq!(a.get_internal_lexed().len(), 1);
        assert_eq!(a.get_internal_lexed()[0].get_kind(), &TokenKind::LiteralString(" [abc\nabc] "));
        assert_eq!(a.get_internal_lexed()[0].get_span(), Span("[==[ [abc\nabc] ]==]"));
    }

    #[test]
    fn test_long_all() {
        let mut a = Lexer::new("and   * \n / break=orville]true~= luna anderson ");
        a.lex_to_end();
        assert_eq!(a.get_internal_view(), "");
        
        let lexed = a.get_internal_lexed();
        // assert_eq!(lexed.len(), 11);
        
        assert_eq!(lexed[0].get_kind(), &TokenKind::Keyword(Keyword::And));
        assert_eq!(lexed[0].get_span(), Span("and"));

        assert_eq!(lexed[1].get_kind(), &TokenKind::Symbol(Symbol::Star));
        assert_eq!(lexed[1].get_span(), Span("*"));
        
        assert_eq!(lexed[2].get_kind(), &TokenKind::Symbol(Symbol::Slash));
        assert_eq!(lexed[2].get_span(), Span("/"));
        
        assert_eq!(lexed[3].get_kind(), &TokenKind::Keyword(Keyword::Break));
        assert_eq!(lexed[3].get_span(), Span("break"));
        
        assert_eq!(lexed[4].get_kind(), &TokenKind::Symbol(Symbol::Equals));
        assert_eq!(lexed[4].get_span(), Span("="));

        assert_eq!(lexed[5].get_kind(), &TokenKind::Identifier);
        assert_eq!(lexed[5].get_span(), Span("orville"));

        assert_eq!(lexed[6].get_kind(), &TokenKind::Symbol(Symbol::RBracket));
        assert_eq!(lexed[6].get_span(), Span("]"));
        
        assert_eq!(lexed[7].get_kind(), &TokenKind::Keyword(Keyword::True));
        assert_eq!(lexed[7].get_span(), Span("true"));
        
        assert_eq!(lexed[8].get_kind(), &TokenKind::Symbol(Symbol::NotEquals));
        assert_eq!(lexed[8].get_span(), Span("~="));

        assert_eq!(lexed[9].get_kind(), &TokenKind::Identifier);
        assert_eq!(lexed[9].get_span(), Span("luna"));
        
        assert_eq!(lexed[10].get_kind(), &TokenKind::Identifier);
        assert_eq!(lexed[10].get_span(), Span("anderson"));
    }
}