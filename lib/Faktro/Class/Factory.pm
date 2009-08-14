package Faktro::Class::Factory;


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
use Class::Inspector;
use Scalar::Util qw();


# ****************************************************************
# class variables
# ****************************************************************

our $VERSION = '0.00_00';


# ****************************************************************
# MOP
# ****************************************************************

use Any::Moose '::Role';    # automatically turn on strict & warnings

# 基底（抽象）クラス名
has 'base_class' => (
    is          => 'ro',
    isa         => 'ClassName',
    default     => q{},
);

no Any::Moose '::Role';


# ****************************************************************
# miscellaneous methods
# ****************************************************************

# ================================================================
# Purpose    : （生成対象の）具象クラス名を（補完して完全修飾名にして）得る
# Usage      : my $concrete_class_name = $class->get_concrete_class($part);
# Parameters : 1) Str : 具象クラス名の一部分
# Returns    : 1) ClassName : 具象クラス名
# Throws     : 1) $class->get_concrete_classした場合
#            :    （このバリデーションは別メソッドに移した方がいいかも）
#            : 2) 具象クラスがロードされていない場合
#            :    （Mooseクラスは動的ロードするとおかしな状態になるので、
#            :    事前の静的ロードを行っておかなければならない）
#            :    ★use autouse xxxxすれば大丈夫かも？
# Comments   : none
# See Also   : n/a
# ----------------------------------------------------------------
sub get_concrete_class : Public {
    my ($self, $name) = @_;

    croak   "Cannot create concrete object: ",
            "this methods runs only as instance method"
                unless defined Scalar::Util::blessed $self;
    my $base_class = $self->base_class;
    $name //= q{};
    my $concrete_class
        = $name =~ m{ \A $base_class ::}xms
            ?                         $name
            : join '::', $base_class, $name;
    croak   "Cannot create account: ",
            "class ($concrete_class) is not loaded yet"
                unless Class::Inspector->loaded($concrete_class);

    return $concrete_class;
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

Faktro::Class::Factory - Role for implementing the Factory pattern


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    # I'll fill it later.


=head1 DESCRIPTION

blah blah blah


=head2 C<blessed>の有効範囲

本クラスに限った話ではなく、L<Mouse|Mouse>を使用するクラス全般についての留意点。

L<Mouse|Mouse>の場合、C<no Mouse>すると、C<use Mouse>でインポートしたC<blessed>ファンクションを名前空間から削除する際に、C<use Mouse>前にC<use Scalar::Util qw(blessed)>していたC<blessed>もお構いなしに削除してしまう。このため、C<unless defined blessed $self;>はC<$self>のインスタンスメソッドとして扱われる（当然、実装していないので例外を投げる）し、C<unless defined blessed($self);>したら、名前空間に存在しない関数のため、同様に例外を投げる。このため、完全修飾名で指定している。その意図を明確にするため、C<use Scalar::Util qw();>ともしている。なお、L<Moose|Moose>では問題ない（C<no Moose>しても、別に入れたC<blessed>は残してくれる）。


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
