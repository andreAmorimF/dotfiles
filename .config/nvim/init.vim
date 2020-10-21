syntax on
filetype plugin indent on

" Force 256 colors
set t_Co=256

" Required for operations modifying multiple buffers like rename.
set hidden

" Enable mouse
set mouse=a

" Line numbers (essential for pair programming)
set number

" access system clipboard instead of vim internal clipboard
set clipboard=unnamed

" changing leaders
let mapleader=','
let maplocalleader = "/"

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

" Rainbow parentheses
let g:rainbow_active = 1

" Conjure always on the right
let g:conjure#log#botright = 1

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

" Improve  Rg parameter passing
function! RipgrepFzf(query, fullscreen)
  let command_fmt = 'rg --column --line-number --no-heading --color=always --smart-case -- %s || true'
  let initial_command = printf(command_fmt, shellescape(a:query))
  let reload_command = printf(command_fmt, '{q}')
  let spec = {'options': ['--phony', '--query', a:query, '--bind', 'change:reload:'.reload_command]}
  call fzf#vim#grep(initial_command, 1, fzf#vim#with_preview(spec), a:fullscreen)
endfunction

" Assigning Rg behavior to improved function RG
command! -nargs=* -bang RG call RipgrepFzf(<q-args>, <bang>0)

" fuzzy search for files of current project
nnoremap <Space><Space> :Files<CR>
nnoremap <Space>s :RG<CR>

" fuzzy search word under the cursor
nnoremap <Space>* :RG <C-r><C-w><CR>

" copy to system dashboard
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" copy from system dashboard
nnoremap <leader>p "+p
vnoremap <leader>p "+p

" deletes instead of cutting
nnoremap d "_d
vnoremap d "_d

" buffer navigation
map gt :bn<cr>
map gT :bp<cr>

" select the whole buffer content
nnoremap <C-A> ggVG

" easier window navigation
nmap <silent> <C-k>  :wincmd k<CR>
nmap <silent> <C-j>  :wincmd j<CR>
nmap <silent> <C-h>  :wincmd h<CR>
nmap <silent> <C-l>  :wincmd l<CR>

" Edit mapping (make cursor keys work like in Windows: <C-Left><C-Right>
" Move to next word.
nnoremap <C-Left> b
vnoremap <C-S-Left> b
nnoremap <C-S-Left> gh<C-O>b
inoremap <C-S-Left> <C-\><C-O>gh<C-O>b

nnoremap <C-Right> w
vnoremap <C-S-Right> w
nnoremap <C-S-Right> gh<C-O>w
inoremap <C-S-Right> <C-\><C-O>gh<C-O>w

" add nu tap
map <leader>nt F<space><space>i#nu/tapd<space><esc>

" remove all nu taps
map <leader>rnt :%s/#nu\/tapd<space>//g<CR><ESC>

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
