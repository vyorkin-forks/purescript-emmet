module Emmet.Halogen where

import Emmet

import Data.Either (Either)
import Data.Foldable (intercalate)
import Data.List (List(..), null, singleton, uncons, (:))
import Data.Maybe (Maybe(..))
import Data.String (Pattern(..), contains)
import Matryoshka as M
import Prelude (map, otherwise, show, (#), (<#>), (<>), (<@>))
import Text.Parsing.Parser (ParseError, runParser)

indent ∷ Int
indent = 4

emmetHalogen ∷ String → Either ParseError String
emmetHalogen s = s
  # runParser <@> parseEmmet
  <#> evalEmmet
  <#> map renderHalogen
  <#> intercalate "\n"

renderHalogen ∷ HtmlBuilder → String
renderHalogen =
  M.cata case _ of
    HtmlBuilderF nodes →
      nodes <#> renderNode # intercalate "\n"

renderNode ∷ Node String → String
renderNode {name, attributes, children} =
  case uncons attributes of
    Nothing → renderNoAttributes name children
    Just {head, tail} → renderWithAttributes name (head : tail) children

renderWithAttributes ∷ String → List HtmlAttribute → List String → String
renderWithAttributes name attributes children =
  "HH." <> name <> "\n"
    <> intercalate "\n" (map (pad indent) (renderList (map renderAttribute attributes)))
    <> "\n"
    <> intercalate "\n" (map (pad indent) (renderList children))
  where
    renderAttribute = case _ of
      HtmlId id → "HP.id " <> show id
      HtmlClass c → "css [" <> show c <> "]"
      HtmlClasses cs → "css [" <> intercalate ", " (map show cs) <> "]"

renderNoAttributes ∷ String → List String → String
renderNoAttributes name children
  | null children = "HH." <> name <> "_ []"
  | otherwise = "HH." <> name <> "_\n" <>
      intercalate "\n" (map (pad indent) (renderList children))

renderList ∷ List String → List String
renderList = case _ of
  Nil → singleton ("[ ]")
  head : Nil →
    if contains (Pattern "\n") head then
      ("[ " <> head) : singleton "]"
    else
      singleton ("[ " <> head <> " ]")
  head : tail →
    ("[ " <> head) : map (", " <> _) tail <> singleton ("]")
