#!/usr/bin/perl -w

use strict;

use Term::App;
use Term::App::Widget::Text;

my $app = Term::App->new({
  child => Term::App::Widget::Text->new({
    text => "foo\nbar\nbaz\n",
  }),
});

$app->loop;
