use crate::{lexer_errors::LexerError, token::{Span, Token}, token_kind::TokenKind};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Keyword {
    And,       Break,     Do,        Else,      Elseif,    End,
    False,     For,       Function,  Goto,      If,        In,
    Local,     Nil,       Not,       Or,        Repeat,    Return,
    Then,      True,      Until,     While,
}

pub fn lex_ident_or_kw<'i>(view: &'i str) -> Result<Option<(Token<'i>,&'i str)>,LexerError> {
    let bytes = view.as_bytes();

    let Some(&b) = bytes.first() else { return Ok(None); };
    if !(b.is_ascii_alphabetic() || b == b'_') {
        return Ok(None);
    }

    let n = bytes.iter()
        .take_while(|&&b| b.is_ascii_alphanumeric() || b == b'_')
        .count();
    
    let something_str = &view[..n];
    let new_view = &view[n..];

    let kind = match something_str {
        "and" => TokenKind::Keyword(Keyword::And),
        "break" => TokenKind::Keyword(Keyword::Break),
        "do" => TokenKind::Keyword(Keyword::Do),
        "elseif" => TokenKind::Keyword(Keyword::Elseif),
        "else" => TokenKind::Keyword(Keyword::Else),
        "end" => TokenKind::Keyword(Keyword::End),
        "false" => TokenKind::Keyword(Keyword::False),
        "for" => TokenKind::Keyword(Keyword::For),
        "function" => TokenKind::Keyword(Keyword::Function),
        "goto" => TokenKind::Keyword(Keyword::Goto),
        "if" => TokenKind::Keyword(Keyword::If),
        "in" => TokenKind::Keyword(Keyword::In),
        "local" => TokenKind::Keyword(Keyword::Local),
        "nil" => TokenKind::Keyword(Keyword::Nil),
        "not" => TokenKind::Keyword(Keyword::Not),
        "or" => TokenKind::Keyword(Keyword::Or),
        "repeat" => TokenKind::Keyword(Keyword::Repeat),
        "return" => TokenKind::Keyword(Keyword::Return),
        "then" => TokenKind::Keyword(Keyword::Then),
        "true" => TokenKind::Keyword(Keyword::True),
        "until" => TokenKind::Keyword(Keyword::Until),
        "while" => TokenKind::Keyword(Keyword::While),
        _ => TokenKind::Identifier,
    };

    Ok(Some((Token::new(kind, Span(something_str)),new_view)))
}