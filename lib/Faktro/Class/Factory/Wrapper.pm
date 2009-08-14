package Faktro::Class::Factory::Wrapper;


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
use Scalar::Util qw();


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

no Any::Moose '::Role';


# ****************************************************************
# parts of constructor
# ****************************************************************

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub instance : Public {
    return (shift)->_instance(0, @_);
};

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : 1) ★本来使えないのに本メソッドを呼べる、という状況は何とかしたい
# See Also   : n/a
# ----------------------------------------------------------------
sub instance_with_config : Public {
    return (shift)->_instance(1, @_);
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub _instance {
    my ($invocant, $with_config, $name, %option) = @_;

    # Factoryインスタンス（ベースクラス名つき）の取得
    my $self = Scalar::Util::blessed $invocant // $invocant->new;

    # Concreteクラスのクラス名を補完する
    my $concrete_class = $self->get_concrete_class($name);

    return $with_config
            ? $concrete_class->new_with_config(%option)
            : $concrete_class->new(%option);
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

Faktro::Class::Factory::Wrapper - Role for wrapping the Factory pattern


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    # I'll fill it later.


=head1 DESCRIPTION

このモジュールは、Flyweightパターンのラッパー用ロールである。

これを使うと、自分でクラス名補完・インスタンス生成の処理を書かなくて済む。


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
