// #[derive(Debug, Clone, PartialEq, Eq)]
pub enum Change<T> {
    Changed(T),
    Unchanged(T),
}

impl<T> Change<T> {
    pub fn from(v: T, changed: bool) -> Self {
        match changed {
            true => Change::Changed(v),
            false => Change::Unchanged(v),
        }
    }
}
