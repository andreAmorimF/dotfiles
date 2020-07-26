syntax on
filetype plugin indent on

" Force 256 colors
set t_Co=256

" Required for operations modifying multiple buffers like rename.
set hidden

" Enable mouse
set mouse=a

call plug#begin('~/.local/share/nvim/plugged')

" NERDCommenter
Plug 'preservim/nerdcommenter'

" NERDTree
Plug 'preservim/nerdtree'
Plug 'Xuyuanp/nerdtree-git-plugin'

" Fzf vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Undotree
Plug 'mbbill/undotree'

" Multiple cursors
Plug 'terryma/vim-multiple-cursors'

" Git stuff
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" Statusline plugin
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" REPL integration
Plug 'Olical/conjure', { 'tag': 'v4.1.0' } "check if this is still the latest version

" Static analysis
Plug 'dense-analysis/ale', {'for': 'clojure'}

" auto complete
Plug 'Shougo/deoplete.nvim'

" rainbow parentheses
Plug 'luochen1990/rainbow'

" structural edition
Plug 'guns/vim-sexp', { 'for': 'clojure' } | Plug 'tpope/vim-sexp-mappings-for-regular-people', { 'for': 'clojure' }

call plug#end()

"Rainbow parentheses
let g:rainbow_active = 1

let g:conjure#log#botright = 1

"line numbers (essential for pair programming)
set number

" access system clipboard instead of vim internal clipboard
set clipboard=unnamed

" use <local leader> K to get docstring trough REPL connection
let g:conjure#mapping#doc_word = "K"

" use gd to jump to definition trough REPL connection
let g:conjure#mapping#def_word = ["gd"]

" clj-kondo ale linter
let g:ale_linters = {
  \ 'python':   ['pylint'],
  \ 'markdown': ['remove_trailing_lines', 'trim_whitespace'],
  \ 'clojure':  ['clj-kondo', 'joker']}

" conjure background colors
highlight NormalFloat ctermbg=grey guibg=grey

" deoplete configuration
let g:deoplete#enable_at_startup = 1
call deoplete#custom#option('keyword_patterns', {'clojure': '[\w!$%&*+/:<=>?@\^_~\-\.#]*'})

" set completeopt to have a better completion experience
set completeopt=menuone,noinsert,noselect
set completeopt-=preview

" avoid showing message extra message when using completion
set shortmess+=c

" theme configuration
colorscheme jellybeans
let g:jellybeans_use_term_italics = 1

" airline config
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'default'
let g:airline_skip_empty_sections = 1
let g:airline_highlighting_cache = 1

" Set this. Airline will handle the rest.
let g:airline#extensions#ale#enabled = 1

let g:fzf_action = {
  \ 'return': 'tab split',
  \ 'ctrl-n': 'e'}

" fuzzy search for files of current project
nnoremap <silent> <C-p> :Files<CR>
nnoremap <silent> <C-o> :Rg<CR>

" copy to system dashboard
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" copy from system dashboard
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" browser like tab navigation
map <C-t><up>    :tabr<CR>
map <C-t><down>  :tabl<CR>
map <C-t><left>  :tabp<CR>
map <C-t><right> :tabn<CR>

" easier window navigation
nmap <silent> <A-Up>    :wincmd k<CR>
nmap <silent> <A-Down>  :wincmd j<CR>
nmap <silent> <A-Left>  :wincmd h<CR>
nmap <silent> <A-Right> :wincmd l<CR>

"Edit mapping (make cursor keys work like in Windows: <C-Left><C-Right>
"Move to next word.
nnoremap <C-Left> b
vnoremap <C-S-Left> b
nnoremap <C-S-Left> gh<C-O>b
inoremap <C-S-Left> <C-\><C-O>gh<C-O>b

nnoremap <C-Right> w
vnoremap <C-S-Right> w
nnoremap <C-S-Right> gh<C-O>w
inoremap <C-S-Right> <C-\><C-O>gh<C-O>w

" toggle nerdtree
nmap <Space>t :NERDTreeToggle<CR>
let NERDTreeCustomOpenArgs={'file':{'where': 't'}}

" toogle undotree
nnoremap <F5> :UndotreeToggle<CR>

" config vim cursor leaving or entering vim
au VimEnter,VimResume * set guicursor=n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50
  \,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor
  \,sm:block-blinkwait175-blinkoff150-blinkon175

au VimLeave,VimSuspend * set guicursor=a:ver26

