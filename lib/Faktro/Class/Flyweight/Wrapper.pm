package Faktro::Class::Flyweight::Wrapper;


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

foreach my $role (qw(
    Faktro::Class::Flyweight
    Faktro::Class::Singleton
)) {
    with $role;
}

# $class->instance('OkasanOnline');でも行けるように、クラス変数ではなく
# Singletonクラスとして取り扱うこととした。
# なお、型バリデーションは$self->new, $self->new_with_configのisaで見るので、
# ここでバリデーションロジックを入れる必要はない。
around 'instance' => sub {
    my ($next, $invocant, $name, %option) = @_ % 2 ? (@_)
                                                   : (shift, shift, undef, @_);

    return $invocant->_get_concrete_instance($next, $name, %option);
};

# Singletonクラスのアトリビュートのデフォルト値をコンフィグファイルで与える
# ……という処理ではない！
# 実クラスのコンストラクタで、アトリビュートのデフォルト値をコンフィグファイル
# で与えるという意味である。紛らわしいので注意。
around 'instance_with_config' => sub {
    my ($next, $invocant, $name, %option) = @_ % 2 ? (@_)
                                                   : (shift, shift, undef, @_);

    return $invocant->instance($name, (%option, _method => 'new_with_config'));
};

no Any::Moose '::Role';


# ****************************************************************
# private methods
# ****************************************************************

# ================================================================
# Purpose    : 具象インスタンスを作成するか、作成済のものを取得する
# Usage      : my $self = $class->_get_concrete_instance($next, $name, %option);
# Parameters : 1)  CodeRef    : 上位メソッド
#            : 2)  Maybe[Str] : 具象クラス名の、基底クラス名以降の部分の文字列
#            : 3-) Hash       : コンストラクターの引数群
# Returns    : Object : $classインスタンスまたは$class::$nameインスタンス
# Throws     : no exceptions
# Comments   : 1) $nameがundefの場合、$class自体が具象クラスである。
# See Also   : n/a
# ----------------------------------------------------------------
sub _get_concrete_instance {
    my ($invocant, $next, $name, %option) = @_;

    # Singletonインスタンス（基底クラス名やFlyweight用stashつき）の取得
    my $self = $next->($invocant);

    # Constant Classのクラス名を補完し、引数に応じたキーも生成する
    my $concrete_class = $self->get_concrete_class($name);
    my $stash_key      = $concrete_class
                       . $self->get_flyweight_key(\%option);
    my $stash_accessor = $self->stash_accessor;
    my $stash_mutator  = $self->stash_mutator;

    # Singletonインスタンスのstashを（なければ実インスタンスを登録して）返す
    my $concrete_instance = $self->$stash_accessor($stash_key);
    if (! $concrete_instance) {
        my $method = $option{_method} // 'new';
        if (exists $option{_parameters}) {
            # Hash以外のオプションが欲しい場合
            $concrete_instance
                = $concrete_class->$method(@{$option{_parameters}});
        }
        else {
            # Hashが欲しい普通のMoose/Mouseコンストラクター
            delete $option{_method};
            $concrete_instance
                = $concrete_class->$method(%option);
        }
        $self->$stash_mutator($stash_key, $concrete_instance);
    }

    return $concrete_instance;
};


# ****************************************************************
# return true
# ****************************************************************

1;
__END__


# ****************************************************************
# POD
# ****************************************************************

=head1 NAME

Faktro::Class::Flyweight::Wrapper - Role for wrapping the Flyweight pattern


=head1 VERSION

0.00_00


=head1 SYNOPSIS

    # I'll fill it later.


=head1 DESCRIPTION

このモジュールは、Flyweightパターンのラッパー用ロールである。

これを使うと、自分でクラス名補完・Flyweight格納用Singletonインスタンス生成・実インスタンス生成の処理を書かなくて済む。


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
