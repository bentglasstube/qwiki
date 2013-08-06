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
  my $latest = schema->resultset('Page')
    ->search({}, { order_by => 'published desc', rows => 10 });

  template 'index', { latest => $latest };
};

get '/search' => sub {
  my $search = '%' . params('q') . '%';
  my $pages = schema->resultset('Page')->search({ body => { like => $search } },
    { group_by => 'name', order_by => 'published desc' });
  template 'list', { pages => $pages };
};

post '/w/:name' => sub {
  my $name  = param('name');
  my $title = param('title');
  my $body  = param('body');

  my $page = schema->resultset('Page')->create({
    name      => param('name'),
    title     => param('title'),
    body      => param('body'),
    published => time(),
    views     => 0,
  });

  redirect '/w/' . $page->name, 303;
};

get '/w/:name' => sub {
  my $name = param('name');
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
      template 'history', { pages => $pages };
    } else {
      template 'view', { page => $page };
    }
  } else {
    template 'edit',
      { page => { name => $name, title => titulize($name), body => '' } };
  }
};

true;
