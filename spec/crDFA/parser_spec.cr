# coding: utf-8
require "../spec_helper"

EXPRESSIONS = [
  "a",
  "ab",
  "abc",
  "a+",
  "a+b",
  "a+b?",
  "a((ab*|c)|b)",
  "a(ab|cd)e",
  "(a|b)*|xy*",
  "([abs]+)*|was ganz anderes",
  "(ab){4}",
  "(ab){4,6}",
  "(ab){14,16}",
  "(ab){1440}",
  "(ab){1440,}",
  "(ab){4,}",
  "[^0-9A-Za-zß]",
  "((http[s]?|ftp):\/)?\/?([^:\/\s]+)((\/\w+)*\/)([\w\-\.]+[^#?\s]+)(.*)?(#[\\w\\-]+)?",
  "\\-?(0|[1-9][0-9]*)(\\.[0-9]+)?((e|E)?(\\+|\\-)?[0-9]+)?",
]

describe DFA::Parser do
  EXPRESSIONS.each do |exp|
    it "parses #{exp}" do
      DFA::Parser.parse(exp, false).to_s.should eq exp
    end
  end

  it "parses non-capturing groups but doesn't recognize them as non-capturing" do
    expression = <<-expression
    (?:[^"\\\\]|\\.)*
    expression

    expected = <<-expression
    ([^"\\\\]|\\.)*
    expression

    DFA::Parser.parse(expression, false).to_s.should eq expected
  end

  it "optimizes away nested star statements and unnecessary groups" do
    expression = <<-expression
    (((a|b)*)*)*
    expression

    ast = DFA::Parser.parse(expression, false)
    ast.to_s.should eq "(((a|b)*)*)*"

    ast = DFA::Parser.parse(expression)
    ast.to_s.should eq "(a|b)*"
  end

  it "optimizes away nested star statements in and around alternation groups" do
    expression = <<-expression
    (a*|b*)*
    expression

    ast = DFA::Parser.parse(expression, false)
    ast.to_s.should eq "(a*|b*)*"

    ast = DFA::Parser.parse(expression)
    ast.to_s.should eq "(a|b)*"

    DFA::Parser.parse("(a*|b*|c*)*").to_s.should eq "(a|b|c)*"
  end

  it "optimizes away nested star statements in and around alternation groups" do
    expression = <<-expression
    (a*|b)*
    expression

    ast = DFA::Parser.parse(expression, false)
    ast.to_s.should eq "(a*|b)*"

    ast = DFA::Parser.parse(expression)
    ast.to_s.should eq "(a|b)*"

    DFA::Parser.parse("(a*|b|c*|d)*").to_s.should eq "(a|b|c|d)*"
  end

  it "splits CharacterClassNodes into atomic (single range) CharacterClassNodes & LiteralNodes" do
    expression = <<-expression
    [a-fi-jxy]
    expression

    ast = DFA::Parser.parse(expression)
    DFA::SmartParsing.detangle_character_ranges(ast).to_s.should eq "[a-f]|[i-j]|x|y"
  end

  it "splits Quantifier into atomic (single range) CharacterClassNodes & LiteralNodes" do
    expression = <<-expression
    a{2}b{2,4}c{4,}[a-z]{3,}
    expression

    expected = "aabbb?b?cccc+[a-z][a-z][a-z]+"

    ast = DFA::Parser.parse(expression)
    DFA::SmartParsing.flatten_out_quantifications(ast).to_s.should eq expected
  end
end
