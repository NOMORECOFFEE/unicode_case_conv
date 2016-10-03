-module(unicode_case_conv).

-compile({parse_transform, ct_expand}).
-compile({parse_transform, parse_trans_codegen}).

%%-pt_pp_src(true).

-export([downcase/1, ex1/0]).

downcase(String) ->
    AccIn = <<>>,
    downcase(String, AccIn).

downcase(<<S/utf8, Rest/binary>>, AccIn) ->
    downcase(Rest, <<AccIn/binary, S/utf8>>);
downcase(<<>>, AccIn) ->
    AccIn.

ex1() ->
    parse_trans_mod:transform_module(
        ?MODULE, [fun do_downcase/2], [{pt_pp_src, true}]).

do_downcase(Forms, _Opts) ->
    Codes = ct_expand:term(
        [{Codepoint, byte_size(Codepoint), Lower} || {Codepoint, Lower, _, _} <- load_special_casing(), Codepoint =/= Lower]
    ),
    NewF =
        codegen:gen_function(
            downcase,
            [ fun(<<S:({'$var', Size})/binary, Rest/binary>>, AccIn) when S == {'$var', CodePoint} ->
                Lower = {'$var', Lower},
                downcase(Rest, <<AccIn/binary, Lower/binary>>)
              end || {CodePoint, Size, Lower} <- Codes]),
    parse_trans:replace_function(downcase, 2, NewF, Forms).

load_special_casing() ->
    {ok, Dir} = file:get_cwd(),
    {ok, Bin} = file:read_file(filename:join([Dir, "src", "SpecialCasing.txt"])),
    [
        {
            to_binary(Codepoint),
            to_binary(Lower),
            to_binary(Title),
            to_binary(Upper)
        } ||
        Line <- binary:split(Bin, <<"\n">>, [global]),
        [Codepoint, Lower, Title, Upper, _] <- [binary:split(Line, <<"; ">>, [global])]
    ].

to_binary(CodePoint) ->
    << <<(binary_to_integer(X, 16))/utf8>> || X <- binary:split(CodePoint, <<" ">>, [global])>>.





