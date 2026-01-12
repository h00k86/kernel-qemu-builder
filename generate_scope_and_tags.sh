




#
# assume cscope and ctags are alredy installed
#


function _initialize_cscope_and_tags(){

    ctags -R .
    cscope -Rbkq
    echo "Tags and cscope database generated."

}




