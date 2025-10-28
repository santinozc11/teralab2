FROM joaquinsr/php-app-db

ENV	MYSQL_ROOT_PASSWORD=example \
	MYSQL_DATABASE=sample \
	MYSQL_USER=sampleuser \
	MYSQL_PASSWORD=samplepass 

COPY ./sql/db.sql /docker-entrypoint-initdb.d/

EXPOSE 3306

#Este CMD es necesario para configurar el plugin de autenticacion default como native password. El comando siguiente
#lo dio claude como una solucion a un que la base de datos no podia leer el entrypoint.
CMD ["mysqld", "--default-authentication-plugin=mysql_native_password", "--log-bin-trust-function-creators=1"]