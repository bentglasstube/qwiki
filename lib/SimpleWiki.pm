package SimpleWiki;

use utf8;
use strict;
use warnings;

use Dancer ':syntax';
use Dancer::Plugin::DBIC;
use Text::Markdown 'markdown';
use URI::Escape;

our $VERSION = '0.1';

sub titulize {
  my $name = uri_unescape(shift);
  $name =~ s/_(\w)/ \U$1\E/g;
  return ucfirst $name;
}

hook 'before_template' => sub {
  my ($tokens) = @_;

  $tokens->{markdown} = sub {
    return markdown(shift, { empty_element_suffix => '>', tab_width => 2 });
  };
};

get '/' => sub {
  my $page = schema->resultset('Page')
    ->search({ name => '' }, { order_by => 'published desc' })->first;
  if ($page) {
    template 'view', { page => $page };
  } else {
    template 'index';
  }
};

get '/latest' => sub {
  my $pages = schema->resultset('Page')
    ->search({}, { order_by => 'published desc', rows => 25 });
  template 'list', { title => 'Latest Changes', pages => $pages };
};

get '/search' => sub {
  my $search = '%' . param('q') . '%';
  my $pages = schema->resultset('Page')->search({ body => { like => $search } },
    { group_by => 'name', order_by => 'published desc' });
  template 'list', { title => 'Search Results', pages => $pages };
};

post qr'/w/(.*)' => sub {
  my ($name) = splat;

  my $page = schema->resultset('Page')->create({
    name      => $name,
    title     => param('title'),
    body      => param('body'),
    published => time(),
    views     => 0,
  });

  redirect '/w/' . $page->name, 303;
};

get qr'/w/(.*)' => sub {
  my ($name) = splat;

  my $time = param('t') || time();
  my $page = schema->resultset('Page')->search(
    { name     => $name,            published => { '<=' => $time } },
    { order_by => 'published desc', rows      => 1 })->first;

  if ($page) {
    if (param('edit')) {
      template 'edit', { page => $page };
    } elsif (param('hist')) {
      my $pages = schema->resultset('Page')
        ->search({ name => $name }, { order_by => 'published desc' });
      template 'history', { title => $page->title, pages => $pages };
    } else {
      template 'view', { page => $page };
    }
  } else {
    template 'edit',
      { page => { name => $name, title => titulize($name), body => '' } };
  }
};

true;
