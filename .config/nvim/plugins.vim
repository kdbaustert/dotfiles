" Plugins
call plug#begin('~/.vim/plugged')
" Plugins here !!!!
Plug 'tpope/vim-sensible'         " Sensible defaults

Plug 'drewtempelmeyer/palenight.vim' " Soothing color scheme for your favorite [best] text editor

Plug 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' } " File navigator
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }     " Install fuzzy finder binary
Plug 'junegunn/fzf.vim'

Plug 'editorconfig/editorconfig-vim'  " Tab/Space trough projects

Plug 'neoclide/coc.nvim', {'branch': 'release'} " Intelisense

Plug 'sheerun/vim-polyglot'

 Plug 'zchee/deoplete-zsh', {'for': ['zsh']}
 Plug 'carlitux/deoplete-ternjs', {'for': ['js'], }

" Snippets
Plug 'sniphpets/sniphpets', { 'for' : ['php'] }
Plug 'sniphpets/sniphpets-phpunit', { 'for' : ['php'] }
Plug 'sniphpets/sniphpets-common', { 'for' : ['php'] }

Plug 'f-person/git-blame.nvim'
Plug 'folke/todo-comments.nvim'
Plug 'unblevable/quick-scope'

" Status Bar
Plug 'hoob3rt/lualine.nvim', { 'commit': '5c20f5f4b8b3318913ed5a9b00cd5610b7295bd4'}
Plug 'akinsho/nvim-bufferline.lua'
Plug 'mte90/vim-no-fixme', {'branch': 'patch-1'}
Plug 'folke/todo-comments.nvim'

" Language support
Plug 'lvht/phpcd.vim', {'for': ['php'], 'do': 'composer install'}
Plug 'othree/html5.vim'
Plug 'gisphm/vim-gitignore'
Plug 'pangloss/vim-javascript', {'for': ['js']}
Plug 'lifepillar/pgsql.vim',  {'for': ['sql']}
Plug 'prettier/vim-prettier', {'do': 'yarn install', 'for': ['js'] + ['ts']}
Plug 'yuezk/vim-js', {'for': ['js']}
Plug 'maxmellon/vim-jsx-pretty', {'for': ['js']}
Plug 'Olical/vim-syntax-expand', {'for': ['js']}
Plug 'mattn/emmet-vim'
Plug 'alvan/vim-closetag',  {'for': ['javascript.jsx', 'typescript.tsx', 'html']}

call plug#end()
