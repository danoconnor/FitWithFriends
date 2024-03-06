import { AbstractGrantType, ServerOptions, BaseModel, InvalidRequestError, Client, Falsey, Request, Token, User} from "@node-oauth/oauth2-server";
import { validateAppleIdToken } from '../utilities/appleIdAuthenticationHelpers';
import * as UserQueries from '../sql/users.queries';
import { convertUserIdToBuffer } from "../utilities/userHelpers";

class AppleIdTokenGrant extends AbstractGrantType {
    private model: BaseModel;

    constructor(options: ServerOptions) {
        super(options);
        this.model = options.model;
    }

    handle(request: Request, client: Client): Promise<Token | Falsey> {
        if (!request.body.userId) {
            console.error('Missing parameter: `userId`');
            throw new InvalidRequestError('Missing parameter: `userId`');
        }
    
        if (!request.body.idToken) {
            console.error('Missing parameter: `idToken`');
            throw new InvalidRequestError('Missing parameter: `idToken`');
        }
    
        const scope = this.getScope(request);
    
        const userId: string = request.body.userId;
        const idToken: string = request.body.idToken;
    
        return Promise.all([this.validateUserExists(userId), validateAppleIdToken(userId, idToken)])
            .then(([userExists, tokenValid]) => {
                if (!userExists) {
                    console.error('Invalid request: User does not exist');
                    throw new InvalidRequestError('Invalid request: User does not exist');
                }

                if (!tokenValid) {
                    console.error('Token validation failed');
                    throw new InvalidRequestError('Token validation failed');
                }

                // The userId will be something like 002261.d372c8cb204940c02479ef472f717857.2341
                // We want the database to handle it as hex to save on storage space, so we'll remove the '.' chars
                // which leaves only valid hex chars remaining
                const hexUserId = userId.replace(/\./g, '');

                return this.saveToken({ id: hexUserId }, client, scope);
            })
            .catch((err) => {
                console.error('Error handling Apple ID token grant:', err);
                throw err;
            });
    }

    saveToken(user: User, client: Client, requestedScope: string[]): Promise<Token | Falsey> {
        var fns = [
            this.validateScope(user, client, requestedScope),
            this.generateAccessToken(client, user, requestedScope),
            this.generateRefreshToken(client, user, requestedScope),
            this.getAccessTokenExpiresAt(),
            this.getRefreshTokenExpiresAt()
        ];

        return Promise.all(fns)
            .then(([validatedScope, accessToken, refreshToken, accessTokenExpiresAt, refreshTokenExpiresAt]) => {
                if (validatedScope === false) {
                    console.error('Invalid scope: Requested scope is invalid');
                    throw new InvalidRequestError('Invalid scope: Requested scope is invalid');
                }

                var token: Token = {
                    client: client,
                    user: user,
                    accessToken: accessToken as string,
                    accessTokenExpiresAt: accessTokenExpiresAt as Date,
                    refreshToken: refreshToken as string,
                    refreshTokenExpiresAt: refreshTokenExpiresAt as Date,
                    scope: validatedScope as string[]
                };

                return this.model.saveToken(token, client, user);
            })
            .catch((err) => {
                console.error('Error saving token:', err);
                return false;
            });
    }

    // Returns true if the given userId exists in the database, false otherwise
    private validateUserExists(userId: string): Promise<boolean> {
        return UserQueries.getUserName({ userId: convertUserIdToBuffer(userId) })
            .then(result => {
                return result.length > 0;
            })
            .catch(err => {
                console.error('Error checking if user exists:', err);
                return false;
            });
    }
}

export default AppleIdTokenGrant;