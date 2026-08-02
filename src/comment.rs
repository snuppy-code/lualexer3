use crate::{lexer_errors::LexerErrorKind, token::Token, token_kind::TokenKind};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Comment<'i>(&'i str);

pub fn lex_comment<'i>(view: &'i str) -> Result<Option<(Token<'i>, &'i str)>, LexerErrorKind> {
    let bytes = view.as_bytes();

    if bytes.starts_with(b"--") {
        return Ok(None);
    }

    match long_opening(bytes) {
        None => lex_short_comment(view),
    }
}

/// returns cursor,
fn long_comment_opening(bytes: &[u8]) -> Option<(usize, usize)> {
    let mut cursor = 2;
    let mut is_long = false;
    let mut opening_eq = 0;

    if bytes.get(cursor) == Some(&b'[') {
        cursor += 1;
        while bytes.get(cursor) == Some(&b'=') {
            cursor += 1;
            opening_eq += 1;
        }
        if bytes.get(cursor) == Some(&b'[') {
            cursor += 1;
            is_long = true;
        }
    }
}

fn lex_short_comment<'i>(view: &'i str) -> Result<Option<(Token<'i>, &'i str)>, LexerErrorKind> {
    // future optimization: iter from cursor, not start of comment
    if let Some(newline_pos) = bytes.iter().position(|&b| b == b'\n') {
        return Ok(Some((
            Token::new(
                TokenKind::Comment(Comment(&view[2..newline_pos])),
                &view[..newline_pos],
            ),
            &view[cursor + newline_pos + 1..],
        )));
    } else {
        return Ok(Some(&view[view.len()..])); // we done,,, end of file
    }
}

fn lex_long_comment<'i>(view: &'i str) -> Result<Option<(Token<'i>, &'i str)>, LexerErrorKind> {
    let mut current = cursor;
    while let Some(bracket_pos) = bytes[current..].iter().position(|&b| b == b']') {
        current += bracket_pos + 1;

        let mut closing_eq = 0;
        while bytes.get(current) == Some(&b'=') {
            closing_eq += 1;
            current += 1;
        }

        if closing_eq == opening_eq && bytes.get(current) == Some(&b']') {
            self.view = &self.view[current + 1..];
            return true;
        }
    }

    return Err(LexerErrorKind::UnclosedLongComment);
}
