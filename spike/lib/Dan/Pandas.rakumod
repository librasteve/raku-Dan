unit module Dan::Pandas;

use Dan;

role Series does Dan::Series is export {
    method yo { "yo" }
}

