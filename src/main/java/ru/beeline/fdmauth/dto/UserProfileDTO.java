package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import ru.beeline.fdmauth.domain.UserProfile;
import ru.beeline.fdmauth.dto.role.RoleInfoDTO;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

import static ru.beeline.fdmauth.utils.Constant.DATE_FORMAT;
import static ru.beeline.fdmauth.utils.Constant.DATE_TIMEZONE;

@Getter
@Setter
public class UserProfileDTO {

    private Long id;

    @JsonProperty("id_ext")
    private String idExt;

    @JsonProperty("full_name")
    private String fullName;

    private String login;

    @JsonProperty("last_login")
    @JsonFormat(pattern = DATE_FORMAT, timezone = DATE_TIMEZONE)
    private Date lastLogin;

    private String email;

    private List<RoleInfoDTO> roles;

    public UserProfileDTO(String idExt, String fullName, String login, String email) {
        this.idExt = idExt;
        this.fullName = fullName;
        this.login = login;
        this.email = email;
    }

    public UserProfileDTO(UserProfile userProfile) {
        this.id = userProfile.getId();
        this.idExt = userProfile.getIdExt();
        this.fullName = userProfile.getFullName();
        this.login = userProfile.getLogin();
        this.lastLogin = userProfile.getLastLogin();
        this.email = userProfile.getEmail();
        this.roles = RoleInfoDTO.convert(userProfile.getUserRoles());
    }

    public static List<UserProfileDTO> convert(List<UserProfile> users) {
        return users.stream()
                .map(UserProfileDTO::new)
                .collect(Collectors.toList());
    }
}
