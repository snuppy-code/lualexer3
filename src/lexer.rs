use crate::{
    change::Change,
    keyword::lex_iden_or_kw,
    lexer_errors::LexerErrorKind,
    literalstring::{lex_long_literal_string, lex_short_literal_string},
    numeric_constant::lex_numeric_constant,
    symbol::lex_symbol,
    token::Token,
};

#[derive(Debug)]
pub struct Lexer<'i> {
    input: &'i str,
    view: &'i str, // substring (inclusive) of input used in lexing
    tokens: Vec<Token<'i>>,
}

impl<'i> Lexer<'i> {
    pub fn new(input: &'i str) -> Lexer<'i> {
        Lexer {
            input: input,
            view: input,
            tokens: Vec::new(),
        }
    }

    pub fn get_view(&self) -> &'i str {
        &self.view
    }
    pub fn iter_tokens(&self) -> core::slice::Iter<'_, Token<'i>> {
        self.tokens.iter()
    }
    pub fn iter_mut_tokens(&mut self) -> std::slice::IterMut<'_, Token<'i>> {
        self.tokens.iter_mut()
    }
    pub fn view_len(&self) -> usize {
        self.view.len()
    }
    pub fn tokens_len(&self) -> usize {
        self.tokens.len()
    }
    pub fn lex_to_end(&mut self) -> Result<(), Vec<LexerErrorKind>> {
        let mut lexing_errors = Vec::new();

        loop {
            loop {
                self.view = skip_whitespace(self.view);
                self.view = trim_start_comment(self.view);
            }
            while self.skip_whitespace() || self.skip_comment() {}

            match lex_one(self.view) {
                Ok(Some((token, new_view))) => {
                    self.tokens.push(token);
                    self.view = new_view;
                }
                Err(e) => {
                    lexing_errors.push(e);
                    self.view = skip_until_whitespace(self.view);
                }
                Ok(None) => break,
            }
        }
        if self.view.len() > 0 {
            todo!();
            // lexing_errors.push(LexerError::FailedLexingAll(self.view));
            return Err(lexing_errors);
        } else {
            return Ok(());
        }
    }
}

fn lex_one<'i>(view: &'i str) -> Result<Option<(Token<'i>, &'i str)>, LexerErrorKind> {
    if let Some(v) = lex_iden_or_kw(view)? {
        return Ok(Some(v));
    }
    if let Some(v) = lex_numeric_constant(view)? {
        return Ok(Some(v));
    }
    if let Some(v) = lex_short_literal_string(view)? {
        return Ok(Some(v));
    }
    if let Some(v) = lex_long_literal_string(view)? {
        return Ok(Some(v));
    }
    lex_symbol(view)
}
