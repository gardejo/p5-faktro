package Faktro::Class::Singleton;


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

no Any::Moose '::Role';


# ****************************************************************
# parts of constructor
# ****************************************************************

# ================================================================
# Purpose    : newではなくinstanceなどのコンストラクタの使用をAPIとして強制する
# Usage      : 1) my $self = $class->new;       # error (invalid usage)
#            : 2) my $self = $class->instance;  # valid usage
# Parameters : 1) Maybe[Hash] : newへのオプション
# Returns    : 2) HashRef : newへのオプション
# Throws     : 1) Singleton機構以外のパッケージからnewを呼ばれた場合
# Comments   : 1) (caller(0))[0]は
#            :    Moose時は'Class::MOP::Method::Generated'、
#            :    Mouse時は'Mouse::Meta::Method::Constructor'である。
#            : 2) (caller(1))[0]はnewの（直感的な）直接の呼び元であるが、
#            :    ConfigFromFileかGetoptの場合もあり、その時は
#            :    (caller(2))[0]こそがnewの（直感的な）直接の呼び元となる。
# See Also   : n/a
# ----------------------------------------------------------------
sub BUILDARGS : Public {
    my $class = shift;

    croak   "Cannot create instance: ",
            "invalid usage. Use $class->instance() instead of $class->new()"
                unless (caller(1))[0] eq __PACKAGE__
                    || (caller(1))[0] =~ m{
                            \A
                            Mo[ou]seX ::
                            (?: ConfigFromFile | Getopt )
                            \z
                        }xms
                    && (caller(2))[0] eq __PACKAGE__;

    return { @_ };
}

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
    return (shift)->_get_singleton_instance(q{}, @_);
}

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
    return (shift)->_get_singleton_instance('config', @_);
}

# ================================================================
# Purpose    : ???
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : 1) ★本来使えないのに本メソッドを呼べる、という状況は何とかしたい
# See Also   : n/a
# ----------------------------------------------------------------
sub instance_with_options : Public {
    return (shift)->_get_singleton_instance('options', @_);
}


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : 既存のSingletonインスタンス返すか、新規に生成する
# Usage      : ???
# Parameters : ???
# Returns    : ???
# Throws     : ??? / no exceptions
# Comments   : 1) $$singleton = $with_config && $invocant->can
#            :                  ('new_with_config')
#            :    とはしない。間違った使い方をした場合に、
#            :    コンフィグファイルを読むつもりで何もエラーが起きずに、
#            :    コンフィグファイルなしのデフォルト値が読まれる方が厄介。
#            :    read-only attributeについても同様。
# See Also   : n/a
# ----------------------------------------------------------------
sub _get_singleton_instance {
    my ($invocant, $with, %option) = @_;

    return $invocant
        if Scalar::Util::blessed $invocant;

    my $singleton;
    {
        no strict qw(refs);
        no warnings qw(once);
        $singleton = \do{ ${$invocant . '::Singleton'} };
    }

    if (defined $$singleton) {
        while (my ($attribute, $value) = each %option) {
            $$singleton->$attribute($value)
                if $$singleton->can($attribute);
        }
    }
    else {
        $$singleton = $with eq 'config'  ? $invocant->new_with_config(%option)
                    : $with eq 'options' ? $invocant->new_with_options(%option)
                    :                      $invocant->new(%option);
    }

    return $$singleton;
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

Faktro::Class::Singleton - Role for implementing the Singleton pattern


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    # I'll fill it later.


=head1 DESCRIPTION

blah blah blah


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
