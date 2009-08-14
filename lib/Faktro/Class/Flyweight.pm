package Faktro::Class::Flyweight;


# ****************************************************************
# pragmas
# ****************************************************************

use 5.010_000;
use utf8;


# ****************************************************************
# general dependencies
# ****************************************************************

use Attribute::Util qw(Abstract Alias Memoize Protected);
use Carp;


# ****************************************************************
# class variables
# ****************************************************************

our $VERSION = '0.00_00';


# ****************************************************************
# MOP
# ****************************************************************

use Any::Moose '::Role';    # automatically turn on strict & warnings

with qw(
    Faktro::Class::Factory
);

# Flyweightメモリーへのアクセッサー
has 'stash_accessor' => (
    is          => 'ro',
    isa         => 'Str',
);

# Flyweightメモリーへのミューテーター
has 'stash_mutator' => (
    is          => 'ro',
    isa         => 'Str',
);

no Any::Moose '::Role';


# ****************************************************************
# miscellaneous methods
# ****************************************************************

# ================================================================
# Purpose    : Flyweightインスタンス格納用メモリー（ハッシュ）のキーを得る
# Usage      : my $hash_key = $self->get_flyweight_key(\%option);
# Parameters : 1) HashRef : コンストラクターへのオプション
# Returns    : 1) Str '' | Str : キー（CGIパラメーターのような線形化文字列）
# Throws     : no exceptions
# Comments   : 1) ハッシュのエントリーポイントを作るイメージである
#            : 2) whileでパラメータを構築すると、ハッシュなので順不同であり、
#            :    同じハッシュから別のFlyweightキーが生じないとも限らない。
#            :    もっとも、ハッシュ関数自体は安定的であるため、そんなことは
#            :    起きないとは思うが、取り敢えずキー順にソートすることとした。
# See Also   : n/a
# ----------------------------------------------------------------
sub get_flyweight_key : Public {
    my ($self, $option) = @_;

    my @flyweight_keys;
    foreach my $key (sort keys %$option) {
        push @flyweight_keys, "$key=" . ($option->{$key} // q{});
    }

    return @flyweight_keys ? (join '&', @flyweight_keys) : q{};
}


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Faktro::Class::Flyweight - Role for implementing the Flyweight pattern


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    # I'll fill it later.


=head1 DESCRIPTION

blah blah blah

C<Flyweight Factory>が必ずしもC<Singleton>である必要はない。
簡単に実装する場合にのみC<Singleton>とする（その場合はL<Faktro::Class::Factory::Wrapper|Faktro::Class::Factory::Wrapper>を使うこと）。


=head1 AUTHOR

=over 4

=item MORIYA Masaki ("Gardejo")

C<< <moriya at ermitejo dot com> >>,
L<http://ttt.ermitejo.com/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008-2009 by MORIYA Masaki ("Gardejo"),
L<http://ttt.ermitejo.com>.

This library is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.
See L<perlgpl|perlapi> and L<perlartistic|perlartistic>.
