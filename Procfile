proxy: gunicorn -b localhost:3000 --pid server.pid \
    -k uvicorn.workers.UvicornWorker -w 4 mynij_proxy:app
