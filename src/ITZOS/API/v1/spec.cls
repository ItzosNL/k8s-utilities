Class ITZOS.API.v1.spec Extends %REST.Spec
{

Parameter Version = "0.1.0";

/// If Strict=0 (false), then only the swagger properties which are needed for code generation are checked during compile.
/// If Strict=1 (true), then all swagger properties are checked during compile.
Parameter Strict = 1;

/// Projection to fix generated classes
Projection Fixer As ITZOS.API.Fixer;

/// For support of CORS
Parameter HandleCorsRequest = 1;

XData OpenAPI [ MimeType = application/json ]
{
{
    "swagger": "2.0",
    "info": {
        "description": "Generic KPN/Itzos Beheer API",
        "version": "Fetched from Version parameter",
        "title": "KPN/Itzos Beheer API",
        "contact": {
            "email": "support@itzos.com"
        }
    },
    "basePath": "/beheer",
    "tags": [
        {
            "name": "Miscellaneous",
            "description": "Various endpoints"
        },
        {
            "name": "Backup",
            "description": "Backup related endpoints"
        },
        {
            "name": "Eventlog",
            "description": "Endpoints voor het ophalen van de eventlog."
        }
    ],
    "securityDefinitions": {
        "basicAuth": {
            "type": "basic"
        }
    },
    "schemes": [
        "https"
    ],
    "paths": {
        "/swagger": {
            "get": {
                "tags": [ 
                    "Miscellaneous"
                ],
                "x-ISC_CORS": true,
                "summary": "Get Swagger spec of this API",
                "operationId": "OpenAPI",
                "produces": [
                    "application/json"
                ],
                "parameters": [],
                "responses": {
                    "200": {
                        "description": "Succes"
                    },
                    "404": {
                        "description": "Not Found"
                    },
                    "500": {
                        "description": "Internal Server Error"
                    }
                }
        }
        },
        "/ping": {
            "get": {
                "tags": [
                    "Miscellaneous"
                ],
                "summary": "Ping service",
                "operationId": "Ping",
                "produces": [
                    "text/plain"
                ],
                "responses": {
                    "200": {
                        "description": "Success"
                    }
                }
            }
        },
	    "/interop/status":{
		    "get": {
			    "tags": [
			    	"Miscellaneous"
			    ],
                "x-ISC_CORS": true,
                "summary": "Status van de interoperability productie",
                "operationId": "GetInteropStatus",
                "consumes": [],
                "produces": [
                    "application/json"
                ],
                "security": [
                    {
                        "basicAuth": []
                    }
                ],
                "parameters": [
                    {
                        "name": "namespace",
                        "in": "query",
                        "type": "string",
                        "description": "Namespace to be queried"
                    }
                ],
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "$ref": "#/definitions/InteropStatusResponse"
                        }
                    },
                    "500": {
                        "description": "Internal Server Error",
                        "schema": {
                            "$ref": "#/definitions/ApiResponse"
                        }
                    }
                }
		    }
	    },
	    "/backups":{
		    "get": {
			    "tags": [
			    	"Backups"
			    ],
                "x-ISC_CORS": true,
                "summary": "Get the backup history, latest backup first",
                "operationId": "GetBackupHistory",
                "consumes": [],
                "produces": [
                    "application/json"
                ],
                "security": [
                    {
                        "basicAuth": []
                    }
                ],
                "parameters": [
                    {
                        "name": "maxage",
                        "in": "query",
                        "type": "string",
                        "description": "Maximum age in days; default is 30, 'all' will include all"
                    }
                ],
                "responses": {
                    "200": {
                        "description": "OK",
                        "schema": {
                            "$ref": "#/definitions/GetBackupHistoryResponse"
                        }
                    },
                    "500": {
                        "description": "Internal Server Error",
                        "schema": {
                            "$ref": "#/definitions/ApiResponse"
                        }
                    }
                }
		    }
	    }
    },
    "definitions": {
        "InteropStatusResponse": {
            "allOf": [
                {
                    "$ref": "#/definitions/ApiResponse"
                },
                {
                    "type": "object",
                    "properties": {
                        "components": {
                            "type": "array",
                            "items": {
                                "$ref": "#/definitions/BusinessComponent"
                            }
                        }
                    }
                }
            ]
        },
        "BusinessComponent": {
            "type": "object",
            "properties": {
                "date-time": {
                    "type": "string",
                    "format": "date-time",
                    "description": "When was the call processed"
                },
                "method": {
                    "type": "string",
                    "description": "Method that was used"
                },
                "endpoint": {
                    "type": "string",
                    "description": "Endpoint that was called"
                },
                "request-body": {
                    "type": "string",
                    "description": "Request Body"
                },
                "token-id": {
                    "type": "integer",
                    "description": "ID of the token that was used"
                },
                "toepassing": {
                    "type": "string",
                    "description": "IRIS Session ID, can be used to find the relevant messages"
                },
                "granted": {
                    "type": "boolean",
                    "description": "Was the request granted?"
                },
                "deny-reason": {
                    "type": "string",
                    "description": "Why was access denied for this request?"
                }
            },
            "additionalProperties": false
        },
        "GetBackupHistoryResponse": {
            "allOf": [
                {
                    "$ref": "#/definitions/ApiResponse"
                },
                {
                    "type": "object",
                    "properties": {
                        "backups": {
                            "type": "array",
                            "items": {
                                "$ref": "#/definitions/Backup"
                            }
                        }
                    }
                }
            ]
        },
        "Backup": {
            "type": "object",
            "properties": {
                "datetime": {
                    "type": "string",
                    "format": "date-time",
                    "description": "File Timestamp (ISO)",
                    "example": "2024-09-10T10:28:04Z"
                },
                "age": {
                    "type": "number",
                    "description": "Age of the backup in days"
                },
                "butype": {
                    "type": "string",
                    "description": "Type of backup (full or cumulative)"
                },
                "status": {
                    "type": "string",
                    "description": "Status of the backup (completed or warning)"
                },
                "logfile": {
                    "type": "string",
                    "description": "Name of the logfile"
                },
                "logfile-status": {
                    "type": "string",
                    "description": "Status of the logfile (present, compressed or absent)"
                },
                "backupfile": {
                    "type": "string",
                    "description": "Name of the backupfile"
                },
                "backupfile-status": {
                    "type": "string",
                    "description": "Status of the backupfile (present, compressed or absent)"
                },
                "journalfile": {
                    "type": "string",
                    "description": "Name of the journalfile"
                },
                "journalfile-status": {
                    "type": "string",
                    "description": "Status of the journalfile (present, compressed or absent)"
                }
            }
        },
        "ApiResponse": {
            "type": "object",
            "properties": {
                "code": {
                    "type": "integer",
                    "format": "int32"
                },
                "message": {
                    "type": "string"
                }
            }
        }
    }
}
}

}
