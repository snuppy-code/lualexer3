use std::fmt::{self, Display};

#[derive(Debug)]
pub enum LexerError<'i> {
    FailedLexingAll(&'i str),
    UnclosedLongComment,
    InvalidStringuEscapeMissingOpenBrace,
    InvalidStringuEscapeMissingClosingBrace,
    InvalidStringuEscapeInvalidChar,
    InvalidStringuEscapeNoDigits,
    InvalidStringuEscapeBeyond0x10FFFF,
    InvalidStringDecimalEscapeBeyondu8,
    InvalidStringEscape,
    UnclosedShortString,
}

impl<'i> Display for LexerError<'i> {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::FailedLexingAll(s) => write!(f,"Encountered unexpected input. remains: `{}`",s),
            Self::UnclosedLongComment => write!(f, "Unclosed long comment."),
            Self::InvalidStringuEscapeMissingOpenBrace => write!(f, ),
            Self::InvalidStringuEscapeMissingClosingBrace => write!(f, ),
            Self::InvalidStringuEscapeInvalidChar => write!(f, ),
            Self::InvalidStringuEscapeNoDigits => write!(f, ),
            Self::InvalidStringuEscapeBeyond0x10FFFF => write!(f, ),
            Self::InvalidStringDecimalEscapeBeyondu8 => write!(f, ),
            Self::InvalidStringEscape => write!(f, ),
            Self::UnclosedShortString => write!(f, ),
        }
	}
}